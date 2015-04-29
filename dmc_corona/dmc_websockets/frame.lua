--====================================================================--
-- dmc_corona/dmc_websockets/frame.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014-2015 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Corona Library : DMC WebSockets Frame
--====================================================================--


--[[

WebSocket support adapted from:
* Lumen (http://github.com/xopxe/Lumen)
* lua-websocket (http://lipp.github.io/lua-websockets/)
* lua-resty-websocket (https://github.com/openresty/lua-resty-websocket)

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.0"



--====================================================================--
--== Imports


local bit = require 'lib.dmc_lua.bit'
local ByteArray = require 'lib.dmc_lua.lua_bytearray'
local Error = require 'dmc_websockets.exception'
local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Setup, Constants


local ProtocolError = Error.ProtocolError

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor

local lshift = bit.lshift
local rshift = bit.rshift
local tohex = bit.tohex
local mmin = math.min
local mfloor = math.floor
local mrandom = math.random
local schar = string.char
local sbyte = string.byte
local ssub = string.sub
local tinsert = table.insert
local tconcat = table.concat

-- Forward declare
local bit_4, bit_7, bit_3_0, bit_6_0, bit_6_4
local decodeCloseFrameData, encodeCloseFrameData

--== WebSockets Constants

local SML_FRAME_SIZE = 125 -- 125 bytes
local MED_FRAME_SIZE = 0xffff -- 65535 bytes
local LRG_FRAME_SIZE = 0xffffffffffffffff -- a lot

local MED_FRAME_TOKEN = 126
local LRG_FRAME_TOKEN = 127

local FRAME_TYPE = {
	[0x0] = "continuation",
	continuation = 0x0,
	[0x1] = "text",
	text = 0x1,
	[0x2] = "binary",
	binary = 0x2,
	[0x8] = "close",
	close = 0x8,
	[0x9] = "ping",
	ping = 0x9,
	[0xa] = "pong",
	pong = 0xa,
}

local CLOSE_CODES = {
	OK = { code=1000, reason="Purpose for connection has been fulfilled" },
	GOING_AWAY = { code=1001, reason="Going Away" },
	PROTO_ERR = { code=1002, reason="Termination due to protocol error" },
	UNHANDLED_DATA = { code=1003, reason="Cannot accept data type" },
	-- 1004, reserved for future use, DO NOT USE
	RESERVED_1004 = { code=1004, reason="reserved, DO NOT USE" },
	-- 1005, internal use only, No status code received
	NO_STATUS_CODE = { code=1005, reason="No status code received" },
	-- 1006, internal use only, Abnormal Close, eg without Close frame
	CONNECTION_CLOSE_ERR = { code=1006, reason="Connection closed abnormally" },
	INVALID_DATA = { code=1007, reason="invalid data received" },
	POLICY_VIOLATION = { code=1008, reason="internal policy violation" },
	MSG_SIZE_ERR = { code=1009, reason="message is too big for processing" },
	EXTENSION_ERR = { code=1010, reason="expected extension negotiation (client)" },
	UNEXPECTED_ERR = { code=1011, reason="unexpected internal error" },
	-- 1015, internal use only, TLS handshake error
	TLS_HANDSHAKE_ERR = { code=1015, reason="TLS handshake failure" },

}
local VALID_CLOSE_CODES = {
	CLOSE_CODES.OK.code,
	CLOSE_CODES.GOING_AWAY.code,
	CLOSE_CODES.PROTO_ERR.code,
	CLOSE_CODES.UNHANDLED_DATA.code,
	CLOSE_CODES.INVALID_DATA.code,
	CLOSE_CODES.POLICY_VIOLATION.code,
	CLOSE_CODES.MSG_SIZE_ERR.code,
	CLOSE_CODES.EXTENSION_ERR.code,
	CLOSE_CODES.UNEXPECTED_ERR.code
}



--====================================================================--
--== Support Functions


local bits = function(...)
	local n = 0
	for _,bitn in pairs{...} do
		n = n + 2^bitn
	end
	return n
end

bit_4 = bits(3)
bit_7 = bits(7)
bit_3_0 = bits(3,2,1,0)
bit_6_0 = bits(6,5,4,3,2,1,0)
bit_6_4 = bits(6,5,4)


local function getunsigned_2bytes_bigendian(s)
	return 256*s:byte(1) + s:byte(2)
end

--from http://stackoverflow.com/questions/5241799/lua-dealing-with-non-ascii-byte-streams-byteorder-change
--adapted for fixed 4 byte bigendian unsigned ints.
local function int_to_bytes( num, endian )
	local res={}
	endian = 'big'
	local n = 4 --math.ceil(select(2,math.frexp(num))/8) -- number of bytes to be used.
	for k=n,1,-1 do -- 256 = 2^8 bits per char.
		local mul=2^(8*(k-1))
		res[k]=mfloor(num/mul)
		num=num-res[k]*mul
	end
	assert(num==0)
	if endian == "big" then
		local t={}
		for k=1,n do
				t[k]=res[n-k+1]
		end
		res=t
	end
	return schar(unpack(res))
end

-- endian big, 4 bytes
local function bytes_to_int( str )
		local t={str:byte(1,4)}
		local n=0
		for k=1,#t do
				n=n+t[#t-k+1]*2^((k-1)*8)
		end
		return n
end

local xor_mask = function( encoded, mask, payload )
	local transformed_arr = {}
	-- xor chunk-wise to prevent stack overflow.
	-- sbyte and schar multiple in/out values
	-- which require stack
	for p=1,payload,2000 do
		local transformed = {}
		local last = mmin(p+1999,payload)
		local original = {sbyte(encoded,p,last)}
		for i=1,#original do
			local j = (i-1) % 4 + 1
			transformed[i] = bxor(original[i],mask[j])
			-- transformed[i] = band(bxor(original[i],mask[j]), 0xFF)
		end
		local xored = schar(unpack(transformed))
		tinsert(transformed_arr,xored)
	end
	return tconcat(transformed_arr)
end




--====================================================================--
--== Main Functions
--====================================================================--


-- forward declarations
local readFrameHeader -- step 1
local processFrameType -- step 2
local processFramePayload -- step 3
local verifyFramePayload -- step 4
local readMaskData -- step 5a
local readPayloadData -- step 5b


-- read header and payload info
readFrameHeader = function( frame, bytearray )
	-- print( "readFrameHeader", bytearray.pos )
	local data = bytearray:readBuf( 2 )
	frame.type, frame.payload = data:byte( 1, 2 )
end

-- process frame type info
processFrameType = function( frame )
	-- print( "processFrameType" )
	frame.fin = band( frame.type, bit_7 ) ~= 0
	frame.opcode = band( frame.type, bit_3_0 )

	-- print( '>>>>', frame.opcode, frame.fin )

	if band( frame.type, bit_6_4 ) ~= 0 then
		error( ProtocolError{
			code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
			message="Data packet too large for control frame" })
		return
	end

	if frame.opcode >= 0x3 and frame.opcode <= 0x7 then
		error( ProtocolError{
			code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
			message="Received reserved non-control frame" } )
		return
	end

	if frame.opcode >= 0xb and frame.opcode <= 0xf then
		error( ProtocolError{
			code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
			message="Received reserved control frame" } )
		return
	end
end

-- process frame payload info
processFramePayload = function( frame, bytearray )
-- print( "processFramePayload", bytearray.pos )

	frame.masked = band( frame.payload, bit_7 ) ~= 0
	frame.payload_len = band( frame.payload, bit_6_0 )

	local payload_len = frame.payload_len
	local data

	if payload_len <= SML_FRAME_SIZE then
		-- pass

	elseif payload_len == MED_FRAME_TOKEN then
		data = bytearray:readBuf( 2 )
		frame.payload_len = bor( lshift( data:byte(1), 8), data:byte(2) )

	elseif payload_len == LRG_FRAME_TOKEN then
		data = bytearray:readBuf( 8 )

		if data:byte(1) ~= 0 or data:byte(2) ~= 0 or
			data:byte(3) ~= 0 or data:byte(4) ~= 0
		then
			error( ProtocolError{
				code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
				message="Payload length too large" } )
			return
		end

		local byte_5 = data:byte(5)
		if band( byte_5, bit_7 ) ~= 0 then
			error( ProtocolError{
				code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
				message="Payload length too large" } )
			return
		end

		frame.payload_len = bor( lshift(byte_5, 24),
												lshift( data:byte(6), 16),
												lshift( data:byte(7), 8),
												data:byte(8) )

	else
		error( ProtocolError{
			code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
			message="Invalid payload size" } )

	end

end

-- verify frame payload
verifyFramePayload = function( frame, bytearray )
	-- print( "verifyFramePayload", bytearray.pos )

	-- control frame check
	if band( frame.opcode, bit_4 ) ~= 0 then
		if frame.payload_len > SML_FRAME_SIZE then
			error( ProtocolError{
				code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
				message="Data packet too large for control frame<<<" } )
			return
		end
		if not frame.fin then
			error( ProtocolError{
				code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
				message="Fragmented control frame" } )
			return
		end
	end

	if frame.masked then
		readMaskData( frame, bytearray )
	else
		readPayloadData( frame, bytearray )
	end

end

-- process frame mask
readMaskData = function( frame, bytearray )
	-- print( "readMaskData", bytearray.pos )
	local data = bytearray:readBuf( 4 )
	local m1,m2,m3,m4 = data:byte( 1, 4 )
	frame.mask = { m1,m2,m3,m4 }
	readPayloadData( frame, bytearray )
end

-- read actual payload data
readPayloadData = function( frame, bytearray )
	-- print( "readPayloadData", bytearray.pos )

	local bytes = frame.payload_len
	local data

	-- Verify Close frame size
	if frame.opcode == FRAME_TYPE.close and not ( bytes == 0 or bytes >= 2 ) then
		error( ProtocolError{
			code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
			message="Data packet wrong size for Close frame" } )
		return
	end

	--== read rest of data

	if bytes == 0 then
		data = ""
	else
		data = bytearray:readBuf( bytes )
	end

	if frame.mask then
		data = xor_mask( data, frame.mask, bytes )
	end

	frame.data = data

	-- Verify Close frame code
	if frame.opcode == FRAME_TYPE.close and bytes >= 2 then
		local code, reason = decodeCloseFrameData( data )

		if code >=0 and code <= 999 then
			error( ProtocolError{
				code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
				message="Invalid close code: %s" % code } )
			return

		elseif code >= 1000 and code <= 2999 then
			if not Utils.propertyIn( VALID_CLOSE_CODES, code ) then
				error( ProtocolError{
					code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
					message="Invalid close code: %s" % code } )
				return
			end

		end
	end
end



-- @params params
-- bytearray ByteArray instance
--
local function receiveWSFrame( bytearray )
	-- print( "receiveWSFrame" )
	assert( bytearray and bytearray:isa( ByteArray ), "ReceiveFrame() requires byte array for data container" )
	--==--

	-- Frame info structure
	local frame = {
		-- header="", basic framing info (string)
		-- payload="", basic framing info (string)
		-- payload_len=0, (number)
		-- fin=true, (boolean)
		-- opcode=0x1, (number)
		-- masked=true, (boolean)
		-- mask={ b1, b2, b3, b4 }, (table)
		-- data="", actual frame data/payload
	}

	readFrameHeader( frame, bytearray )
	processFrameType( frame, bytearray )
	processFramePayload( frame, bytearray )
	verifyFramePayload( frame, bytearray )

	return {
		opcode=frame.opcode,
		type=FRAME_TYPE[ frame.opcode ],
		data=frame.data,
		fin=frame.fin
	}
end


-- @params params table structure
-- data: data to send
-- fin: boolean, end of data packet
-- opcode: type of message to send
-- masked: boolean, masked packet
--
local function buildFrame( params )
	-- print( "buildFrame" )

	local msg = params.msg
	local data = params.data
	local fin = params.fin
	local opcode = params.opcode
	local masked = params.masked

	local payload_len = #data
	local frame = {} -- frame info

	-- frame header vars
	local h_type, h_payload = opcode, 0

	--== process header

	if fin == nil or fin == true then
		h_type = bor( h_type, bit_7 )
	end

	if masked then
		h_payload = bor( h_payload, bit_7 )
	end

	if payload_len <= SML_FRAME_SIZE then
		h_payload = bor( h_payload, payload_len )
		tinsert( frame, schar( h_type, h_payload ) )

	elseif payload_len <= MED_FRAME_SIZE then
		h_payload = bor( h_payload, MED_FRAME_TOKEN )
		tinsert( frame, schar( h_type, h_payload, mfloor(payload_len/256), payload_len%256 ) )

	elseif payload_len < 2^53 then
		h_payload = bor( h_payload, LRG_FRAME_TOKEN )

		local high = mfloor( payload_len / 2^32 )
		local low = payload_len - high*2^32
		tinsert( frame, schar( h_type, h_payload ) )
		tinsert( frame, int_to_bytes( high ) )
		tinsert( frame, int_to_bytes( low ) )

	else
		error( ProtocolError{
			code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
			message="Data packet too big for protocol" } )

	end

	--== process mask

	if not masked then
		tinsert( frame, data )

	else
		local m1 = mrandom( 0, 0xff )
		local m2 = mrandom( 0, 0xff )
		local m3 = mrandom( 0, 0xff )
		local m4 = mrandom( 0, 0xff )
		local mask = { m1,m2,m3,m4 }

		tinsert( frame, schar( m1, m2, m3, m4 ) )
		tinsert( frame, xor_mask( data, mask, #data ) )

	end

	return tconcat( frame )

end


-- @param data
-- @param opcode
-- @param masked
-- @param onFrame
-- @param max_frame_size
local function buildWSFrames( params )
	-- print( "buildWSFrames" )

	local msg = params.message
	local data_len = msg:getAvailable()

	local opcode
	if msg.start == 1 then
		opcode = msg.opcode
	else
		opcode = FRAME_TYPE.continuation
	end

	local max_frame_size = params.max_frame_size
	if max_frame_size and max_frame_size > LRG_FRAME_SIZE then
		max_frame_size = LRG_FRAME_SIZE
	end

	-- control frame check
	if band( opcode, bit_4 ) ~= 0 then
		if data_len > SML_FRAME_SIZE then
			error( ProtocolError{
				code=CLOSE_CODES.PROTO_ERR.code, reason=CLOSE_CODES.PROTO_ERR.code,
				message="Data packet too large for control frame" } )
			return
		end
	end

	local divisor, chunk, fin
	local frame

	if max_frame_size then
		divisor = max_frame_size
	elseif data_len <= SML_FRAME_SIZE then
		divisor = SML_FRAME_SIZE
	elseif data_len <= MED_FRAME_SIZE then
		divisor = MED_FRAME_SIZE
	else
		divisor = LRG_FRAME_SIZE
	end

	chunk = msg:read( divisor )

	fin = ( msg:getAvailable() == 0 )

	frame = buildFrame{
		data=chunk,
		fin=fin,
		masked=msg.masked,
		opcode=opcode
	}

	return { frame=frame }

end


encodeCloseFrameData = function(code,reason)
	local data
	if code and type(code) == 'number' then
		--data = spack('>H',code)
		data = schar(mfloor(code/256),code%256)
		if reason then
			data = data..tostring(reason)
		end
	end

	return data or ''
end


decodeCloseFrameData = function( data )
	local _,code,reason
	if data then
		if #data > 1 then
			code = getunsigned_2bytes_bigendian(data)
		end
		if #data > 2 then
			reason = data:sub(3)
		end
	end
	return code, reason
end



--====================================================================--
--== Module Facade
--====================================================================--


return {
	type = FRAME_TYPE,
	close = CLOSE_CODES,
	size = {
		SMALL = SML_FRAME_SIZE,
		MEDIUM = MED_FRAME_SIZE,
		LARGE = LRG_FRAME_SIZE
	},

	receiveFrame = receiveWSFrame,
	buildFrames = buildWSFrames,
	encodeCloseFrameData = encodeCloseFrameData,
	decodeCloseFrameData = decodeCloseFrameData
}


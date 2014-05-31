--====================================================================--
-- frame.lua (part of dmc_websockets)
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_websockets.lua
--====================================================================--

--[[

Copyright (C) 2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]

--[[

WebSocket support adapted from:
* Lumen (http://github.com/xopxe/Lumen)
* lua-websocket (http://lipp.github.io/lua-websockets/)
* lua-resty-websocket (https://github.com/openresty/lua-resty-websocket)

--]]



-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports
--====================================================================--

local bit = require( dmc_lib_func.find('bit') )

local band = bit.band
local bor = bit.bor
local bxor = bit.bxor

local lshift = bit.lshift
local rshift = bit.rshift
local tohex = bit.tohex
local mmin = math.min
local mrandom = math.random
local schar = string.char
local sbyte = string.byte
local ssub = string.sub
local tinsert = table.insert
local tconcat = table.concat


--====================================================================--
-- Setup, Constants
--====================================================================--

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
	PROTOERR = { code=1002, reason="Termination due to protocol error" },
}

local bit_4, bit_7, bit_3_0, bit_6_0, bit_6_4


--====================================================================--
-- Support Functions
--====================================================================--

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
local function int_to_bytes( num )
		local res={}
		local n = 4 --math.ceil(select(2,math.frexp(num))/8) -- number of bytes to be used.
		for k=n,1,-1 do -- 256 = 2^8 bits per char.
				local mul=2^(8*(k-1))
				res[k]=math.floor(num/mul)
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
		return string.char(unpack(res))
end

local function bytes_to_int( str, endian )
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
		end
		local xored = schar(unpack(transformed))
		tinsert(transformed_arr,xored)
	end
	return tconcat(transformed_arr)
end


--====================================================================--
-- Main Functions
--====================================================================--

-- @params socket
-- @params onFrame
-- @params onError
--
local function receiveWSFrame( params )
	-- print( "receiveWSFrame" )

	local socket = params.socket
	local onFrame = params.onFrame
	local onError = params.onError

	-- holds frame info
	local frame = {
		-- header="", basic framing info (string)
		-- payload="", basic framing info (string)
		-- payload_len=0, (number)
		-- fin=true, (boolean)
		-- opcode=0x1, (number)
		-- masked=true, (boolean)
		-- mask={ b1, b2, b3, b4 }, (table)
	}

	local readFrameHeader -- step 1
	local processFrameType -- step 2
	local processFramePayload -- step 3
	local verifyFramePayload -- step 4
	local readMaskData -- step 5a
	local readPayloadData -- step 5b


	--== read header and payload info

	readFrameHeader = function()
		-- print( 'receiveWSFrame:readFrameHeader' )

		local recv_cb = function( event )
			-- print("socket receive callback: readFrameHeader")
			local data, emsg = event.data, event.emsg

			if not data then
				onError( { is_error=true, error=-1, emsg="failed to receive the first 2 bytes: " .. emsg } )
				return
			end

			frame.type, frame.payload = data:byte( 1, 2 )
			processFrameType()

		end
		socket:receive( 2, recv_cb )

	end  -- readFrameHeader


	--== process frame type info

	processFrameType = function()
	-- print( 'receiveWSFrame:processFrameType' )

		frame.fin = band( frame.type, bit_7 ) ~= 0
		frame.opcode = band( frame.type, bit_3_0 )

		if band( frame.type, bit_6_4 ) ~= 0 then
			onError( { is_error=true, error=-1, emsg="bad RSV1, RSV2, or RSV3 bits" } )
			return
		end

		if frame.opcode >= 0x3 and frame.opcode <= 0x7 then
			onError( { is_error=true, error=-1, emsg="reserved non-control frames" } )
			return
		end

		if frame.opcode >= 0xb and frame.opcode <= 0xf then
			onError( { is_error=true, error=-1, emsg="reserved control frames" } )
			return
		end

		processFramePayload()

	end  -- processFrameType


	--== process frame payload info

	processFramePayload = function()
	-- print( 'receiveWSFrame:processFramePayload' )

		frame.masked = band( frame.payload, bit_7 ) ~= 0
		frame.payload_len = band( frame.payload, bit_6_0 )

		local payload_len = frame.payload_len
		local recv_cb

		if payload_len > LRG_FRAME_TOKEN then
			onError( { is_error=true, error=-1, emsg="invalid payload" } )
			return

		elseif payload_len <= SML_FRAME_SIZE then
			verifyFramePayload()

		elseif payload_len == MED_FRAME_TOKEN then

			recv_cb = function( event )
				-- print("socket receive callback: processFramePayload", MED_FRAME_TOKEN )
				local data, emsg = event.data, event.emsg

				if not data then
					onError( { is_error=true, error=-1, emsg="failed to receive the 2 byte payload length: " .. (emsg or "unknown") } )
					return
				end

				frame.payload_len = bor( lshift( data:byte(1), 8), data:byte(2) )

				-- other lib
				-- pos,payload = 3, getunsigned_2bytes_bigendian(encoded)

				verifyFramePayload()

			end
			socket:receive( 2, recv_cb )

		elseif payload_len == LRG_FRAME_TOKEN then

			recv_cb = function( event )
				-- print("socket receive callback: processFramePayload", LRG_FRAME_TOKEN )
				local data, emsg = event.data, event.emsg

				if not data then
					onError( { is_error=true, error=-1, emsg="failed to receive the 2 byte payload length: " .. (emsg or "unknown") } )
					return
				end

				if data:byte(1) ~= 0 or data:byte(2) ~= 0 or
					data:byte(3) ~= 0 or data:byte(4) ~= 0
				then
					onError( { is_error=true, error=-1, emsg="payload length too large" } )
					return
				end

				local byte_5 = data:byte(5)
				if band( byte_5, bit_7 ) ~= 0 then
					onError( { is_error=true, error=-1, emsg="payload length too large" } )
					return
				end

				frame.payload_len = bor( lshift(byte_5, 24),
														lshift( data:byte(6), 16),
														lshift( data:byte(7), 8),
														data:byte(8) )

				verifyFramePayload()

			end
			socket:receive( 8, recv_cb )

		end

	end  -- processFramePayload


	--== verify frame payload

	verifyFramePayload = function()
		-- print( 'receiveWSFrame:verifyFramePayload' )

		-- control frame check
		if band( frame.opcode, bit_4 ) ~= 0 then
			if frame.payload_len > SML_FRAME_SIZE then
				onError( { is_error=true, error=-1, emsg="data too large for control frame" } )
				return
			end
			if not frame.fin then
				evt =
				onError( { is_error=true, error=-1, emsg="fragmented control frame" })
				return
			end
		end

		if frame.masked then
			readMaskData()
		else
			readPayloadData()
		end

	end  -- verifyFramePayload


	--== process frame mask

	readMaskData = function()
		-- print("calling processMaskedData")

		local recv_cb

		recv_cb = function( event )
			-- print( 'receiveWSFrame:readPayloadData' )
			local data, emsg = event.data, event.emsg

			local m1,m2,m3,m4

			if not data then
				onError( { is_error=true, error=-1, emsg="failed to receive the data: " .. (emsg or "unknown") } )
				return
			end

			m1,m2,m3,m4 = data:byte(1,4)
			frame.mask = { m1,m2,m3,m4 }

			readPayloadData()

		end
		socket:receive( 4, recv_cb )

	end  -- readMaskData


	--== read and process rest of data

	readPayloadData = function()
		-- print( 'receiveWSFrame:readPayloadData' )

		local bytes = frame.payload_len
		local recv_cb

		if frame.opcode == FRAME_TYPE.close and bytes < 2 then
			onError( { is_error=true, error=-1, emsg="Close frame must have at least 2-byte status code" } )
			return
		end

		-- read rest of data

		recv_cb = function( event )

			-- print( "socket receive callback: readPayloadData" )
			local data, emsg = event.data, event.emsg

			if not data then
				onError( { is_error=true, error=-1, emsg="failed to receive the data: " .. (emsg or "unknown") } )
				return
			end

			if frame.mask then
				data = xor_mask( data, frame.mask, bytes )
			end

			if onFrame then
				onFrame( { type=FRAME_TYPE[ frame.opcode ], data=data } )
			end

		end

		if bytes == 0 then
			recv_cb( { data="" } )
		else
			socket:receive( bytes, recv_cb )
		end

	end  -- readPayloadData

	-- start processing frame
	readFrameHeader()

end


-- @params data
-- @params fin
-- @params opcode
-- @params masked
--
local function buildFrame( params )
	-- print( "buildFrame" )

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
		table.insert( frame, string.char( h_type, h_payload ) )

	elseif payload_len < MED_FRAME_SIZE then
		h_payload = bor( h_payload, MED_FRAME_TOKEN )
		table.insert( frame, string.char( h_type, h_payload, math.floor(payload_len/256), payload_len%256 ) )

	elseif payload_len < LRG_FRAME_SIZE then
		h_payload = bor( h_payload, LRG_FRAME_TOKEN )

		local high = math.floor( payload_len / 2^32 )
		local low = payload_len - high*2^32
		table.insert( frame, string.char( h_type, h_payload ) )
		table.insert( frame, int_to_bytes( high ) )
		table.insert( frame, int_to_bytes( low ) )

	end


	--== process mask

	if not masked then
		table.insert( frame, data )

	else
		local m1 = mrandom( 0, 0xff )
		local m2 = mrandom( 0, 0xff )
		local m3 = mrandom( 0, 0xff )
		local m4 = mrandom( 0, 0xff )
		local mask = { m1,m2,m3,m4 }

		table.insert( frame, string.char( m1, m2, m3, m4 ) )
		table.insert( frame, xor_mask( data, mask, #data ) )

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

	local data = params.data or ""
	local opcode = params.opcode or FRAME_TYPE.text
	local masked = params.masked or true
	local onFrame = params.onFrame

	local max_frame_size = params.max_frame_size
	if max_frame_size and max_frame_size > LRG_FRAME_SIZE then
		max_frame_size = LRG_FRAME_SIZE
	end

	local data_len, evt

	if type( data ) ~= 'string' then
		data = tostring( data )
	end

	data_len = #data

	-- control frame check
	if band( opcode, bit_4 ) ~= 0 then
		if data_len > SML_FRAME_SIZE then
			evt = { error=true, emsg="data too large for control frame" }
			if onFrame then onFrame( evt ) end
			return
		end
	end

	-- build frames from data

	repeat

		local divisor, chunk, fin
		local p, frame

		if max_frame_size then
			divisor = max_frame_size
		elseif data_len <= SML_FRAME_SIZE then
			divisor = SML_FRAME_SIZE
		elseif data_len <= MED_FRAME_SIZE then
			divisor = MED_FRAME_SIZE
		else
			divisor = LRG_FRAME_SIZE
		end

		chunk = data:sub( 1, divisor )
		data = data:sub( divisor+1 )

		data_len = #data
		fin = ( data_len == 0 )

		p = {
			data=chunk,
			fin=fin,
			masked=masked,
			opcode=opcode
		}
		frame = buildFrame( p )

		if onFrame and frame then
			evt = { frame=frame }
			onFrame( evt )
		end

		if not fin then
			coroutine.yield()
			opcode = FRAME_TYPE.continuation
		end

	until fin

end


local encodeCloseFrameData = function(code,reason)
	local data
	if code and type(code) == 'number' then
		--data = spack('>H',code)
		data = string.char(math.floor(code/256),code%256)
		if reason then
			data = data..tostring(reason)
		end
	end

	return data or ''
end


local decodeCloseFrameData = function( data )
	local _,code,reason
	if data then
		if #data > 1 then
			--_,code = sunpack(data,'>H')
			code = getunsigned_2bytes_bigendian(data)
		end
		if #data > 2 then
			reason = data:sub(3)
		end
	end
	return code,reason
end



--====================================================================--
-- Module Facade
--====================================================================--

return {

	type = FRAME_TYPE,
	size = {
		SMALL = SML_FRAME_SIZE,
		MEDIUM = MED_FRAME_SIZE,
		LARGE = LRG_FRAME_SIZE
	},
	close_code = CLOSE_CODES,

	receiveFrame = receiveWSFrame,
	buildFrames = buildWSFrames,
	encodeCloseFrameData = encodeCloseFrameData,
	decodeCloseFrameData = decodeCloseFrameData

}


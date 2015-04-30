--====================================================================--
-- dmc_lua/bytearray.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014- 2015 David McCuskey

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
--== DMC Lua Library: Lua Byte Array
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.4.0"



--====================================================================--
--== Imports


local Error = require 'lua_bytearray.exceptions'
local Class = require 'lua_class'

local has_pack, PackByteArray = pcall( require, 'lua_bytearray.pack_bytearray' )



--====================================================================--
--== Setup, Constants


local ObjectBase = Class.ObjectBase

local assert = assert
local iwrite = io.write
local mceil = math.ceil
local sbyte = string.byte
local schar = string.char
local sfind = string.find
local sformat = string.format
local ssub = string.sub
local tinsert = table.insert
local type = type

local Parents = { Class.Class }
if has_pack then
	tinsert( Parents, PackByteArray )
end



--====================================================================--
--== Support Functions


local Utils = {}


-- hexDump()
-- pretty-print data in hex table
--
function Utils.hexDump( buf )
	for i=1,mceil(#buf/16) * 16 do
		if (i-1) % 16 == 0 then iwrite(sformat('%08X  ', i-1)) end
		iwrite( i > #buf and '   ' or sformat('%02X ', buf:byte(i)) )
		if i %  8 == 0 then iwrite(' ') end
		if i % 16 == 0 then iwrite( buf:sub(i-16+1, i):gsub('%c','.'), '\n' ) end
	end
end



--====================================================================--
--== Byte Array Class
--====================================================================--


local ByteArray = newClass( Parents, { name="Byte Array" } )


--======================================================--
-- Start: Setup Lua Objects

function ByteArray:__new__( params )
	-- print( "ByteArray:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	self._endian = params.endian
	self._buf = "" -- buffer is string of bytes
	self._pos = 1 -- current position for reading

end

-- END: Setup Lua Objects
--======================================================--


--====================================================================--
--== Static Methods


function ByteArray.getBytes( buffer, index, length )
	-- print( "ByteArray:getBytes", buffer, index, length )
	assert( type(buffer)=='string', "buffer must be string" )
	--==--
	local idx_end
	index = index or 1
	assert( index>=1 and index<=#buffer+1, "index out of range" )
	assert( type(index)=='number', "start index must be a number" )

	if length~=nil then
		idx_end = index + length - 1
	end

	return ssub( buffer, index, idx_end )
end

function ByteArray.putBytes( buffer, bytes, index )
	-- print( "ByteArray:putBytes", buffer, bytes, #bytes, index )
	assert( type(buffer)=='string', "buffer must be string" )
	assert( type(bytes)=='string', "bytes must be string" )
	--==--
	if not index then
		return buffer .. bytes
	end

	assert( type(index)=='number', "index must be a number" )
	assert( index>=1 and index<=#buffer+1, "index out of range" )

	local buf_len, byte_len = #buffer, #bytes
	local result, buf_start, buf_end

	if index == 1 and byte_len >= buf_len then
		result = bytes
	elseif index == 1 and byte_len < buf_len then
		buf_end = ssub( buffer, byte_len+1 )
		result = bytes .. buf_end
	elseif index <= buf_len and buf_len < (index + byte_len) then
		buf_start = ssub( buffer, 1, index-1 )
		result = buf_start .. bytes
	else
		buf_start = ssub( buffer, 1, index-1 )
		buf_end = ssub( buffer, index+byte_len )
		result = buf_start .. bytes .. buf_end
	end

	return result
end



--====================================================================--
--== Public Methods


function ByteArray.__getters:endian()
	return self._endian
end

function ByteArray.__setters:endian( value )
	self._endian = value
end


function ByteArray.__getters:length()
	return #self._buf
end

function ByteArray.__getters:bytesAvailable()
	return #self._buf - (self._pos-1)
end



function ByteArray.__getters:position()
	return self._pos
end

function ByteArray.__setters:position( pos )
	assert( type(pos)=='number', "position value must be integer" )
	assert( pos >= 1 and pos <= self.length + 1 )
	--==--
	self._pos = pos
	return self
end


function ByteArray:toHex()
	Utils.hexDump( self._buf )
end


function ByteArray:toString()
	return self._buf
end


function ByteArray:search( str )
	assert( type(str)=='string', "search value must be string" )
	--==--
	return sfind( self._buf, str )
end


function ByteArray:readBoolean()
	return (self:readByte() ~= 0)
end

function ByteArray:writeBoolean( boolean )
	assert( type(boolean)=='boolean', "expected boolean type" )
	--==--
	if boolean then
		self:writeByte(1)
	else
		self:writeByte(0)
	end
	return self -- chaining
end


-- byte is number from 0<>255
function ByteArray:readByte()
	return sbyte( self:readChar() )
end

function ByteArray:writeByte( byte )
	assert( type(byte)=='number', "not valid byte" )
	assert( byte>=0 and byte<=255, "not valid byte" )
	--==--
	self:writeChar( schar(byte) )
end


function ByteArray:readChar()
	self:_checkAvailable(1)
	local char = self.getBytes( self._buf, self._pos, 1 )
	self._pos = self._pos + 1
	return char
end

-- should be single character
function ByteArray:writeChar( char )
	self._buf = self.putBytes( self._buf, char )
	return self
end



-- Read byte string from ByteArray starting from current position,
-- then update the position
function ByteArray:readUTFBytes( len )
	-- print( "ByteArray:readUTFBytes", len, self._pos )
	assert( type(len)=='number', "need integer length" )
	--==--
	if len == 0 then return "" end
	self:_checkAvailable( len )
	local bytes = self.getBytes( self._buf, self._pos, len )
	self._pos = self._pos + len
	return bytes
end

ByteArray.readBuf = ByteArray.readUTFBytes

--- Write a encoded char array into buf
function ByteArray:writeUTFBytes( bytes, index )
	assert( type(bytes)=='string', "must be string" )
	--==--
	self._buf = ByteArray.putBytes( self._buf, bytes, index )
	return self -- chaining
end

ByteArray.writeBuf = ByteArray.writeUTFBytes



-- reads bytes FROM us TO array
-- ba array to read TO
-- length for ba being read from
-- offset for ba being written to
--
function ByteArray:readBytes( ba, offset, length )
	assert( ba and ba:isa(ByteArray), "Need a ByteArray instance" )
	--==--
	offset = offset ~= nil and offset or 1
	length = length ~= nil and length or ba.bytesAvailable
	if length == 0 then return end

	assert( type(offset)=='number', "offset must be a number" )
	assert( type(length)=='number', "offset must be a number" )

	local bytes = self:readUTFBytes( length )
	ba._buf = ByteArray.putBytes( ba._buf, bytes, offset )

	return self -- chaining
end


-- write bytes TO us FROM array
-- ba array to write FROM
-- length for ba being read from
-- offset for ba being written to
--
function ByteArray:writeBytes( ba, offset, length )
	assert( ba and ba:isa(ByteArray), "Need a ByteArray instance" )
	--==--
	offset = offset ~= nil and offset or 1
	length = length ~= nil and length or ba.bytesAvailable
	if length == 0 then return end

	assert( type(offset)=='number', "offset must be a number" )
	assert( type(length)=='number', "offset must be a number" )

	local bytes = ba:readUTFBytes( length )
	self._buf = ByteArray.putBytes( self._buf, bytes, offset )

	return self -- chaining
end



--====================================================================--
--== Private Methods


function ByteArray:_checkAvailable( len )
	-- print( "ByteArray:_checkAvailable", len )
	if len > self.bytesAvailable then
		error( Error.BufferError("Read surpasses buffer size") )
	end
end



return ByteArray

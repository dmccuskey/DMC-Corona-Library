--====================================================================--
-- dmc_lua/bytearray.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_bytearray.lua
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
this is a very simple byte array.
i would use my lua_bytearray module, but it doesn't run on standard Corona
since pack isn't available
--]]



--====================================================================--
--== Byte Array
--====================================================================--

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local Objects = require 'lua_objects'
local ByteArrayError = require 'lua_bytearray.exceptions'
local BufferError = ByteArrayError.BufferErrorFactory


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase



--====================================================================--
--== Byte Array Class
--====================================================================--


local ByteArray = inheritsFrom( ObjectBase )
ByteArray.NAME = "Byte Array"


--======================================================--
-- Start: Setup Lua Objects

function ByteArray:_init( params )
	-- print( "ByteArray:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	self._buf = "" -- buffer is string of bytes
	self._pos = 1 -- current position for reading

end

-- END: Setup Lua Objects
--======================================================--


--====================================================================--
--== Static Methods

function ByteArray.getBytes( buffer, idx_start, idx_end )
	-- print( "ByteArray:getBytes", buffer, idx_start, idx_end )
	assert( type(buffer)=='string', "buffer must be string" )
	--==--
	idx_start = idx_start or 1
	idx_end = idx_end or #buffer
	return string.sub( buffer, idx_start, idx_end )
end

function ByteArray.putBytes( buffer, bytes, index )
	-- print( "ByteArray:putBytes", buffer, #bytes, index )
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
		buf_end = string.sub( buffer, byte_len+1 )
		result = bytes .. buf_end
	elseif index <= buf_len and buf_len < (index + byte_len) then
		buf_start = string.sub( buffer, 1, index-1 )
		result = buf_start .. bytes
	else
		buf_start = string.sub( buffer, 1, index-1 )
		buf_end = string.sub( buffer, index+byte_len )
		result = buf_start .. bytes .. buf_end
	end

	return result
end


--====================================================================--
--== Public Methods

function ByteArray:getLen()
	return #self._buf
end

function ByteArray:getAvailable()
	return #self._buf - (self._pos-1)
end


function ByteArray.__getters:pos()
	return self._pos
end

function ByteArray.__setters:pos(pos)
	assert( type(pos)=='number', "position value must be integer")
	assert( pos >= 1 and pos <= self:getLen() + 1 )
	--==--
	self._pos = pos
	return self
end

function ByteArray:search( str )
	assert( type(str)=='string', "search value must be string")
	--==--
	return string.find( self._buf, str )
end


-- Read byte string from ByteArray starting from current position,
-- then update the position
function ByteArray:readBuf( len )
	-- print( "ByteArray:readBuf", len, self._pos)
	assert( type(len)=='number', "need integer length" )
	--==--
	if len == 0 then return "" end
	self:_checkAvailable( len )
	local bytes = self.getBytes( self._buf, self._pos, (self._pos-1) + len )
	self._pos = self._pos + len
	return bytes
end

--- Write a encoded char array into buf
function ByteArray:writeBuf( bytes, index )
	assert( type(bytes)=='string', "must be string" )
	--==--
	self._buf = ByteArray.putBytes( self._buf, bytes, index )
	return self -- chaining
end


-- reads bytes from another array, puts those end
function ByteArray:readFromArray( ba, offset, length )
	assert( ba and ba:isa(ByteArray), "Need a ByteArray instance" )
	--==--
	local ba_len = ba:getLen()
	if ba_len == 0 then return end

	offset = offset or 1
	length = length or ( ba_len - offset+1 )

	local orig_pos = ba.pos
	ba.pos = offset
	local bytes = ba:readBuf( length )
	ba.pos = orig_pos
	self._buf = ByteArray.putBytes( self._buf, bytes )

	return self -- chaining
end


--====================================================================--
--== Private Methods

function ByteArray:_checkAvailable( len )
	-- print( "ByteArray:_checkAvailable", len )
	if len > self:getAvailable() then
		error( BufferError( "Read surpasses buffer size" ) )
	end
end



return ByteArray

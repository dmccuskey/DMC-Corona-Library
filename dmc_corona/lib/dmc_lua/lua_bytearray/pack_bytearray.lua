--====================================================================--
-- dmc_lua/lua_bytearray/pack_bytearray.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014-2015 David McCuskey

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


--[[
based off work from zrong(zengrong.net)
https://github.com/zrong/lua#ByteArray
https://github.com/zrong/lua/blob/master/lib/zrong/zr/utils/ByteArray.lua
--]]



--====================================================================--
--== DMC Lua Library: Lua Byte Array (pack)
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== Imports


require 'pack'



--====================================================================--
--== Setup, Constants


local spack = string.pack
local sunpack = string.unpack



--====================================================================--
--== Pack Byte Array Class
--====================================================================--


local ByteArray = {}

ByteArray.ENDIAN_LITTLE = 'endian-little'
ByteArray.ENDIAN_BIG = 'endian-big'



--====================================================================--
--== Public Methods


function ByteArray:readDouble()
	self:_checkAvailable(8)
	local _, val = sunpack(self:readBuf(8), self:_getLC('d'))
	return val
end

function ByteArray:writeDouble( double )
	local str = spack( self:_getLC('d'), double )
	self:writeBuf( str )
	return self
end


function ByteArray:readFloat()
	self:_checkAvailable(4)
	local _, val = sunpack(self:readBuf(4), self:_getLC('f'))
	return val
end

function ByteArray:writeFloat( float )
	local str = spack( self:_getLC('f'), float)
	self:writeBuf( str )
	return self
end


function ByteArray:readInt()
	self:_checkAvailable(4)
	local _, val = sunpack(self:readBuf(4), self:_getLC('i'))
	return val
end

function ByteArray:writeInt( int )
	local str = spack( self:_getLC('i'), int )
	self:writeBuf( str )
	return self
end


function ByteArray:readLong()
	self:_checkAvailable(8)
	local _, val = sunpack(self:readBuf(8), self:_getLC('l'))
	return val
end

function ByteArray:writeLong( long )
	local str = spack( self:_getLC('l'), long )
	self:writeBuf( str )
	return self
end


function ByteArray:readMultiByte( len )
	error("not implemented")
	return val
end

function ByteArray:writeMultiByte( int )
	error("not implemented")
	return self
end


function ByteArray:readStringBytes( len )
	assert( len , "Need a length of the string!")
	if len == 0 then return "" end
	self:_checkAvailable( len )
	local __, __v = sunpack(self:readBuf( len ), self:_getLC( 'A'.. len ))
	return __v
end

function ByteArray:writeStringBytes(__string)
	local __s = spack(self:_getLC('A'), __string)
	self:writeBuf(__s)
	return self
end


function ByteArray:readStringUnsignedShort()
	local len = self:readUShort()
	return self:readStringBytes( len )
end

ByteArray.readStringUShort = ByteArray.readStringUnsignedShort

function ByteArray:writeStringUnsignedShort( ustr )
	local str = spack(self:_getLC('P'),  ustr )
	self:writeBuf( str )
	return self
end

ByteArray.writeStringUShort = ByteArray.writeStringUnsignedShort



function ByteArray:readShort()
	self:_checkAvailable(2)
	local _, val = sunpack(self:readBuf(2), self:_getLC('h'))
	return val
end

function ByteArray:writeShort( short )
	local str = spack( self:_getLC('h'), short )
	self:writeBuf( str )
	return self
end


function ByteArray:readUnsignedByte()
	self:_checkAvailable(1)
	local _, val = sunpack(self:readChar(), 'b')
	return val
end

ByteArray.readUByte = ByteArray.readUnsignedByte

function ByteArray:writeUnsignedByte( ubyte )
	local str = spack('b', ubyte )
	self:writeBuf( str )
	return self
end

ByteArray.writeUByte = ByteArray.writeUnsignedByte


function ByteArray:readUnsignedInt()
	self:_checkAvailable(4)
	local _, val = sunpack(self:readBuf(4), self:_getLC('I'))
	return val
end

ByteArray.readUInt = ByteArray.readUnsignedInt

function ByteArray:writeUInt( uint )
	local str = spack(self:_getLC('I'), uint )
	self:writeBuf( str )
	return self
end

ByteArray.writeUInt = ByteArray.writeUnsignedInt


function ByteArray:readUnsignedLong()
	self:_checkAvailable(4)
	local _, val = sunpack(self:readBuf(4), self:_getLC('L'))
	return val
end

ByteArray.readULong = ByteArray.readUnsignedLong

function ByteArray:writeUnsignedLong( ulong )
	local str = spack( self:_getLC('L'), ulong )
	self:writeBuf( str )
	return self
end

ByteArray.writeULong = ByteArray.writeUnsignedLong


function ByteArray:readUnsignedShort()
	self:_checkAvailable(2)
	local _, val = sunpack(self:readBuf(2), self:_getLC('H'))
	return val
end

ByteArray.readUShort = ByteArray.readUnsignedShort

function ByteArray:writeUnsignedShort( ushort )
	local str = spack(self:_getLC('H'), ushort )
	self:writeBuf( str )
	return self
end

ByteArray.writeUShort = ByteArray.writeUnsignedShort



--====================================================================--
--== Private Methods


function ByteArray:_getLC( format )
	 format = format  or ""
	if self._endian == ByteArray.ENDIAN_LITTLE then
		return "<".. format
	elseif self._endian == ByteArray.ENDIAN_BIG then
		return ">".. format
	end
	return "=".. format
end



return ByteArray

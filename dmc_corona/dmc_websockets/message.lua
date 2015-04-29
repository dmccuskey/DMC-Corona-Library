--====================================================================--
-- dmc_corona/dmc_websockets/message.lua
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
--== DMC Corona Library : DMC WebSockets Message
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.0"



--====================================================================--
--== Imports


local ByteArray = require 'lib.dmc_lua.lua_bytearray'
local Objects = require 'lib.dmc_lua.lua_objects'



--====================================================================--
--== Setup, Constants


local ObjectBase = Objects.ObjectBase



--====================================================================--
--== WebSocket Message Class
--====================================================================--


local Message = newClass( ObjectBase, { name="WebSocket Message" } )


--==================================================--
-- Start: Setup DMC Objects

function Message:__init__( params )
	-- print( "Message:__init__" )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self.masked = params.masked
	self.opcode = params.opcode
	self._bytearray = nil

	self._data = params.data -- tmp

end

function Message:__initComplete__()
	-- print( "Message:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--

	local ba = ByteArray:new()
	ba:writeBuf( self._data )
	self._bytearray = ba
	self._data = nil -- erase tmp

end

-- END: Setup DMC Objects
--==================================================--



--====================================================================--
--== Public Methods


function Message.__getters:start()
	-- print( "Message.__getters:start" )
	return self._bytearray.position
end


function Message:getAvailable()
	-- print( "Message:getAvailable" )
	return self._bytearray.bytesAvailable
end

-- reads chunk of data. if value > available data
-- or value==nil then return all data
--
function Message:read( value )
	-- print( "Message:read", value )
	local avail = self:getAvailable()
	if value > avail or value == nil then value = avail end
	return self._bytearray:readBuf( value )
end




return Message

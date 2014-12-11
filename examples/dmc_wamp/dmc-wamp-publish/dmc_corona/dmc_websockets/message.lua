--====================================================================--
-- dmc_websockets/message.lua
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


--====================================================================--
-- dmc_websockets : Message
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local ByteArray = require 'dmc_websockets.bytearray'
local Objects = require 'lua_objects'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase



--====================================================================--
-- WebSocket Message Class
--====================================================================--


local Message = inheritsFrom( ObjectBase )
Message.NAME = "WebSocket Message"

--====================================================================--
--== Start: Setup Lua Objects

function Message:_init( params )
	-- print( "Message:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Create Properties ==--

	self.masked = params.masked
	self.opcode = params.opcode
	self._bytearray = nil

	self._data = params.data -- tmp

end

function Message:_initComplete()
	-- print( "Message:_initComplete" )

	local ba = ByteArray()
	ba:writeBuf( self._data )
	self._bytearray = ba
	self._data = nil

end

--== END: Setup Lua Objects
--====================================================================--


--====================================================================--
--== Public Methods

function Message.__getters:start()
	-- print( "Message.__getters:start" )
	return self._bytearray.pos
end


function Message:getAvailable()
	-- print( "Message:getAvailable" )
	return self._bytearray:getAvailable()
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

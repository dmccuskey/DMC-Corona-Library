--====================================================================--
-- dmc_websockets/exception.lua
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
-- DMC Corona Library : Exception
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local Error = require 'lua_error'
local Objects = require 'lua_objects'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom



--====================================================================--
--== Protocol Error Class
--====================================================================--


local ProtocolError = inheritsFrom( Error )
ProtocolError.NAME = "Protocol Error"


function ProtocolError:_init( params )
	-- print( "ProtocolError:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	if not self.is_intermediate then
		assert( params.code, "missing protocol code")
	end

	self.code = params.code
	self.reason = params.reason or ""

end




--====================================================================--
--== Exception Facade
--====================================================================--

local function ProtocolErrorFactory( message )
	-- print( "ProtocolErrorFactory", message )
	return ProtocolError:new{ message=message }
end

return {
	ProtocolError=ProtocolError,
	ProtocolErrorFactory=ProtocolErrorFactory,
}

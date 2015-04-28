--====================================================================--
-- dmc_lua/lua_megaphone.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2013-2015 David McCuskey

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
--== DMC Lua Library : Lua Megaphone
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.0"



--====================================================================--
--== Imports


local Objects = require 'lua_objects'



--====================================================================--
--== Setup, Constants


local ObjectBase = Objects.ObjectBase

local singleton = nil



--====================================================================--
--== Megaphone Class
--====================================================================--


local Megaphone = newClass( ObjectBase, { name="Lua Megaphone" } )

--== Event Constants ==--

Megaphone.EVENT = 'megaphone_event'


--======================================================--
-- Start: Setup Lua Objects

--[[
function Megaphone:__new__( ... )
	-- print( "Megaphone:__new__" )
end
--]]

--[[
function Megaphone:__destroy__( ... )
	-- print( "Megaphone:__destroy__" )
	EventsMix.__undoInit__( self )
end
--]]

-- END: Setup Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


function Megaphone:say( message, data, params )
	-- print( "Megaphone:say ", message )
	params = params or {}
	assert( type(message)=='string', "Megaphone:say, arg 'message' must be a string" )
	assert( params==nil or type(params)=='table', "Megaphone:say, arg 'params' must be a table" )
	--==--
	self:dispatchEvent( message, data, params )
end
function Megaphone:listen( listener )
	-- print( "Megaphone:listen " )
	assert( type(listener)=='function', "Megaphone:listen, arg 'listener' must be a function" )
	--==--
	self:addEventListener( Megaphone.EVENT, listener )
end
function Megaphone:ignore( listener )
	-- print( "Megaphone:ignore " )
	assert( type(listener)=='function', "Megaphone:ignore, arg 'listener' must be a function" )
	--==--
	self:removeEventListener( Megaphone.EVENT, listener )
end



singleton = Megaphone:new()

return singleton

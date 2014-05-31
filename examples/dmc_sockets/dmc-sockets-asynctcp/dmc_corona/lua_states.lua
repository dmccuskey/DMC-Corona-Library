--====================================================================--
-- lua_states.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_states.lua
--====================================================================--

--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

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
-- DMC Lua Library : Lua States
--====================================================================--

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.1"


--====================================================================--
-- Setup, Constants

local tinsert = table.insert
local tremove = table.remove



--====================================================================--
-- States Container
--====================================================================--


local States = {}

States._DEBUG = false


--== State API Methods ==--


function States._setState( self, state )
	if States._DEBUG then
		print( "Lua States::setState: is now >> " .. tostring( state ) )
	end

	local f = self[ state ]

	assert( type(f)=='function', "\n\nERROR: Lua States :: missing state method '" .. tostring( state ) .. "'\n\n" )

	self._curr_state = f
	self._curr_state_name = state
end


function States._gotoState( self, state, ... )
	if States._DEBUG then
		print( "Lua States::gotoState: " .. tostring( state ) )
	end

	tinsert( self._state_stack, 1, self._curr_state_name )
	self:_curr_state( state, ... )
end


function States._gotoPreviousState( self, ... )
	local state = tremove( self._state_stack, 1 )
	if States._DEBUG then
		print( "Lua States::gotoPreviousState: going to >> " .. tostring( state ) )
	end

	self:_curr_state( state, ... )
end


function States._getState( self )
	return self._curr_state_name
end


function States._getPreviousState( self )
	return self._state_stack[1]
end


function States._pushState( self, state_name )
	tinsert( self._state_stack, 1, state_name )
end


function States._resetStates( self )
	if States._DEBUG then
		print( "Lua States::resetStates" )
	end
	self._state_stack = {}
	self._curr_state = nil
	self._curr_state_name = ""
end


--== Facade API Methods ==--


function States._setDebug( value )
	States._DEBUG = value
end


function States._mixin( obj )
	if States._DEBUG then
		print( "Lua States::mixin: ", obj )
	end

	obj = obj or {}

	-- add variables
	States._resetStates( obj )

	-- add methods
	obj.setState = States._setState
	obj.gotoState = States._gotoState
	obj.gotoPreviousState = States._gotoPreviousState
	obj.getState = States._getState
	obj.getPreviousState = States._getPreviousState
	obj.pushState = States._pushState
	obj.resetStates = States._resetStates

	return obj
end




--====================================================================--
-- States Facade
--====================================================================--

return {
	setDebug = States._setDebug,
	mixin = States._mixin
}



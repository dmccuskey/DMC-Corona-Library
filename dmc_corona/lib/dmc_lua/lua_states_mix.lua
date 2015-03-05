--====================================================================--
-- dmc_lua/lua_states_mix.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.

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
--== DMC Lua Library : Lua States Mixin
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.3.1"



--====================================================================--
--== Setup, Constants


local tinsert = table.insert
local tremove = table.remove

local States



--====================================================================--
--== Support Functions


-- create general output string
function outStr( msg )
	return "Lua States (debug) :: " .. tostring( msg )
end

-- create general error string
function errStr( msg )
	return "\n\nERROR: Lua States :: " .. tostring( msg ) .. "\n\n"
end



function _patch( obj )

	obj = obj or {}

	-- add properties
	States.__init__( obj )

	-- add methods
	obj.resetStates = States.resetStates
	obj.getState = States.getState
	obj.setState = States.setState
	obj.gotoState = States.gotoState
	obj.getPreviousState = States.getPreviousState
	obj.gotoPreviousState = States.gotoPreviousState
	obj.pushStateStack = States.pushStateStack
	obj.popStateStack = States.popStateStack
	obj.setDebug = States.setDebug

	-- private method, for testing
	obj._stateStackSize = States._stateStackSize

	return obj
end



--====================================================================--
--== States Mixin
--====================================================================--


States = {}

States.NAME = "States Mixin"

--======================================================--
-- Start: Mixin Setup for Lua Objects

function States.__init__( self, params )
	-- print( "States.__init__" )
	params = params or {}
	--==--
	States.resetStates( self, params )
end

function States.__undoInit__( self )
	-- print( "States.__undoInit__" )
	States.resetStates( self )
end

-- END: Mixin Setup for Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


function States.resetStates( self, params )
	params = params or {}
	if params.debug_on==nil then params.debug_on=false end
	--==--
	if self.__debug_on then
		print( outStr( "resetStates: resetting object states" ) )
	end
	self.__state_stack = {}
	self.__curr_state_func = nil
	self.__curr_state_name = ""
	self.__debug_on = params.debug_on
end



function States.getState( self )
	return self.__curr_state_name
end

function States.setState( self, state_name )
	assert( state_name, errStr("missing state name") )
	assert( type(state_name)=='string', errStr("state name must be string'" .. tostring( state_name ) ) )
	--==--

	if self.__debug_on then
		print( outStr("setState: is now '" .. tostring( state_name ) .. "'" ) )
	end
	local f = self[ state_name ]

	assert( type(f)=='function', errStr("missing method for state name: '" .. tostring( state_name ) ) )

	self.__curr_state_func = f
	self.__curr_state_name = state_name
end

function States.gotoState( self, state_name, ... )
	assert( state_name, errStr("no state name given") )
	assert( self.__curr_state_func, errStr("no initial state method") )
	--==--

	if self.__debug_on then
		print( outStr("gotoState: '" .. self.__curr_state_name .. "' >> '".. tostring( state_name ) .. "'" ) )
	end

	self:pushStateStack( self.__curr_state_name )
	self.__curr_state_func( self, state_name, ... )
end



function States.getPreviousState( self )
	assert( #self.__state_stack > 0, errStr("state stack is empty") )

	return self.__state_stack[1]
end

function States.gotoPreviousState( self, ... )
	local state_name = self:popStateStack()

	assert( state_name, errStr("no state name given") )
	assert( self.__curr_state_func, errStr("no initial state method") )

	if self.__debug_on then
		print( outStr("gotoPreviousState: going to >> " .. tostring( state_name ) ) )
	end

	self.__curr_state_func( self, state_name, ... )
end



function States.pushStateStack( self, state_name )
	assert( self.__state_stack, errStr("no state stack: did you init() ??") )
	assert( state_name, errStr("no state name given") )
	tinsert( self.__state_stack, 1, state_name )
end

function States.popStateStack( self )
	assert( #self.__state_stack > 0, errStr("state stack is empty") )
	return tremove( self.__state_stack, 1 )
end



function States.setDebug( self, value )
	self.__debug_on = value
end



-- private method, for testing
function States._stateStackSize( self )
	return #self.__state_stack
end




--====================================================================--
--== States Facade
--====================================================================--


return {
	StatesMix=States,

	patch=_patch,
}




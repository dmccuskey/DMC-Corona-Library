--====================================================================--
-- dmc_states.lua
--
--
-- by David McCuskey
-- Documentation:
--====================================================================--

--[[

Copyright (C) 2013 David McCuskey. All Rights Reserved.

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


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
-- Boot Support Methods
--====================================================================--

local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end



--====================================================================--
-- DMC Library Config
--====================================================================--

local dmc_lib_data, dmc_lib_info, dmc_lib_location

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_library_boot" ) end ) then
	_G.__dmc_library = {
		dmc_library={
			location = ''
		},
		func = {
			find=function( name )
				local loc
				if dmc_lib_data[name] and dmc_lib_data[name].location then
					loc = dmc_lib_data[name].location
				elseif dmc_lib_info.location then
					loc = dmc_lib_info.location
				else
					loc = ''
				end
				if loc ~= '' and string.sub( loc, -1 ) ~= '.' then
					loc = loc .. '.'
				end
				return loc
		end		}
	}
end

dmc_lib_data = _G.__dmc_library
dmc_lib_func = dmc_lib_data.func
dmc_lib_info = dmc_lib_data.dmc_library
dmc_lib_location = dmc_lib_info.location




--====================================================================--
-- DMC Library : DMC States
--====================================================================--



--====================================================================--
-- Configuration
--====================================================================--

dmc_lib_data.dmc_states = dmc_lib_data.dmc_states or {}

local DMC_STATES_DEFAULTS = {
	debug_active=true,
}

local dmc_states_data = Utils.extend( dmc_lib_data.dmc_states, DMC_STATES_DEFAULTS )


--====================================================================--
-- Imports
--====================================================================--



--====================================================================--
-- Setup, Constants
--====================================================================--

local States = {}

States._DEBUG = dmc_states_data.debug_active or false



--====================================================================--
-- Support Methods
--====================================================================--



--====================================================================--
-- States Object
--====================================================================--


--== State API Methods ==--


local function States._setState( self, state )
	if States._DEBUG then
		print( "DMC States::setState: is now >> " .. tostring( state ) )
	end

	local f = self[ state ]
	if f then
		self._curr_state = f
		self._curr_state_name = state
	else
		print( "\n\nERROR: missing state method '" .. tostring( state ) .. "'\n\n")
	end
end


local function States._gotoState( self, state, ... )
	if States._DEBUG then
		print( "DMC States::gotoState: " .. tostring( state ) )
	end

	table.insert( self._state_stack, 1, self._curr_state_name )
	self:_curr_state( state, ... )
end


local function States._gotoPreviousState( self, ... )
	local state = table.remove( self._state_stack, 1 )
	if States._DEBUG then
		print( "DMC States::gotoPreviousState: going to >> " .. tostring( state ) )
	end

	self:_curr_state( state, ... )
end


local function States._getState( self )
	return self._curr_state_name
end


local function States._getPreviousState( self )
	return self._state_stack[1]
end



--== Facade API Methods ==--


local function States._setDebug( value )
	States._DEBUG = value
end


local function States._mixin( obj )
	if States._DEBUG then
		print( "DMC States::mixin: ", obj )
	end

	obj = obj or {}

	-- add variables
	obj._state_stack = {}
	obj._curr_state = nil
	obj._curr_state_name = ""

	-- add methods
	obj.setState = States._setState
	obj.gotoState = States._gotoState
	obj.gotoPreviousState = States._gotoPreviousState
	obj.getState = States._getState
	obj.getPreviousState = States._getPreviousState

	return obj
end




--====================================================================--
-- States Facade Object
--====================================================================--

local StateFacade = {}

StateFacade.setDebug = States._setDebug
StateFacade.mixin = States._mixin

return StateFacade


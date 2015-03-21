--====================================================================--
-- dmc_lua/lua_events_mix.lua
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
--== DMC Lua Library : Lua Events Mixin
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.2"



--====================================================================--
--== Setup, Constants


local Events
local Utils = {} -- make copying from Utils easier

local sfmt = string.format



--====================================================================--
--== Support Functions


--== Start: copy from lua_utils ==--

function Utils.createObjectCallback( object, method )
	assert( object ~= nil, "missing object in Utils.createObjectCallback" )
	assert( method ~= nil, "missing method in Utils.createObjectCallback" )
	--==--
	return function( ... )
		return method( object, ... )
	end
end

--== End: copy from lua_utils ==--


-- callback is either function or object (table)
-- creates listener lookup key given event name and handler
--
local function _createEventListenerKey( e_name, handler )
	return e_name .. "::" .. tostring( handler )
end



-- return event unmodified
--
local function _createCoronaEvent( obj, event )
	return event
end



-- obj,
-- event type, string
-- data, anything
-- params, table of params
-- params.merge, boolean, if to merge data (table) in with event table
--
local function _createDmcEvent( obj, e_type, data, params )
	params = params or {}
	if params.merge==nil then params.merge=false end
	--==--
	local e

	if params.merge and type( data ) == 'table' then
		e = data
		e.name = obj.EVENT
		e.type = e_type
		e.target = obj

	else
		e = {
			name=obj.EVENT,
			type=e_type,
			target=obj,
			data=data
		}

	end
	return e
end



local function _patch( obj )

	obj = obj or {}

	-- add properties
	Events.__init__( obj )
	obj.EVENT = Events.EVENT -- generic event name

	-- add methods
	obj.dispatchEvent = Events.dispatchEvent
	obj.addEventListener = Events.addEventListener
	obj.removeEventListener = Events.removeEventListener

	obj.setDebug = Events.setDebug
	obj.setEventFunc = Events.setEventFunc

	return obj
end



--====================================================================--
--== Events Mixin
--====================================================================--


Events = {}

Events.EVENT = 'event_mix_event'


--======================================================--
-- Start: Mixin Setup for Lua Objects

function Events.__init__( self, params )
	-- print( "Events.__init__" )
	params = params or {}
	--==--

	--[[
	event listeners key'd by:
	* <event name>::<function>
	* <event name>::<object>
	{
		<event name> = {
			'event::function' = func,
			'event::object' = object (table)
		}
	}
	--]]
	self.__event_listeners = {}  -- holds event listeners

	self.__debug_on = false
	self.__event_func = params.event_func or _createDmcEvent
end

function Events.__undoInit__( self )
	-- print( "Events.__undoInit__" )
	self.__event_listeners = nil
	self.__debug_on = nil
	self.__event_func = nil
end

-- END: Mixin Setup for Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


function Events.createCallback( self, method )
	return Utils.createObjectCallback( self, method )
end

function Events.setDebug( self, value )
	assert( type(value) == 'boolean', "setDebug requires boolean" )
	self.__debug_on = value
end

function Events.setEventFunc( self, func )
	assert( func and type(func)=='function', 'setEventFunc requires function' )
	self.__event_func = func
end


function Events.createEvent( self, ... )
	return self.__event_func( self, ... )
end

function Events.dispatchEvent( self, ... )
	-- print( "Events.dispatchEvent" )
	local f = self.__event_func
	self:_dispatchEvent( f( self, ... ) )
end

function Events.dispatchRawEvent( self, event )
	-- print( "Events.dispatchRawEvent", event )
	assert( type(event)=='table', "wrong type for event" )
	assert( event.name, "event must have property 'name'")
	--==--
	self:_dispatchEvent( event )
end



-- addEventListener()
--
function Events.addEventListener( self, e_name, listener )
	-- print( "Events.addEventListener", e_name, listener )
	assert( type(e_name)=='string', sfmt( "Events.addEventListener event name should be a string, received '%s'", tostring(e_name)) )
	assert( type(listener)=='function' or type(listener)=='table', sfmt( "Events.addEventListener callback should be function or object, received '%s'", tostring(listener) ))

	-- Sanity Check

	if not e_name or type(e_name)~='string' then
		error( "ERROR addEventListener: event name must be string", 2 )
	end
	if not listener and not Utils.propertyIn( {'function','table'}, type(listener) ) then
		error( "ERROR addEventListener: listener must be a function or object", 2 )
	end

	-- Processing

	local events, listeners, key

	events = self.__event_listeners
	if not events[ e_name ] then events[ e_name ] = {} end
	listeners = events[ e_name ]

	key = _createEventListenerKey( e_name, listener )
	if listeners[ key ] then
		print("WARNING:: Events:addEventListener, already have listener")
	else
		listeners[ key ] = listener
	end

end

-- removeEventListener()
--
function Events.removeEventListener( self, e_name, listener )
	-- print( "Events.removeEventListener" );

	local listeners, key

	listeners = self.__event_listeners[ e_name ]
	if not listeners or type(listeners)~= 'table' then
		print( "WARNING:: Events:removeEventListener, no listeners found" )
	end

	key = _createEventListenerKey( e_name, listener )

	if not listeners[ key ] then
		print( "WARNING:: Events:removeEventListener, listener not found" )
	else
		listeners[ key ] = nil
	end

end



--====================================================================--
--== Private Methods


function Events:_dispatchEvent( event )
	-- print( "Events:_dispatchEvent", event.name );
	local e_name, listeners

	e_name = event.name
	if not e_name or not self.__event_listeners[ e_name ] then return end

	listeners = self.__event_listeners[ e_name ]
	if type(listeners)~='table' then return end

	for k, callback in pairs( listeners ) do

		if type( callback ) == 'function' then
			-- have function
		 	callback( event )

		elseif type( callback )=='table' and callback[e_name] then
			-- have object/table
			local method = callback[e_name]
			method( callback, event )

		else
			print( "WARNING: Events dispatchEvent", e_name )

		end
	end
end




--====================================================================--
--== Events Facade
--====================================================================--


return {
	EventsMix=Events,

	dmcEventFunc=_createDmcEvent,
	coronaEventFunc=_createCoronaEvent,

	patch=_patch,
}



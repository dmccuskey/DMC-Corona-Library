--====================================================================--
-- lua_objects.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_objects.lua
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014 David McCuskey

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
-- DMC Lua Library : Lua Objects
--====================================================================--



-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

-- 'lua_utils' is required for a couple of functions
-- those functions can be put into this class if wanted
--
local Utils = require 'lua_utils'


--====================================================================--
-- Setup, Constants

-- the name of the constructor method can be changed
-- to work with other OO frameworks
--
local CONSTRUCTOR_FUNC_NAME = 'new'

local function setConstructorName( name )
	assert( type(name)=='string' )
	CONSTRUCTOR_FUNC_NAME = name
end


--====================================================================--
-- Class Support Functions

-- printObject()
-- print out the keys contained within a table.
-- by default, does not process items with underscore '_'
--
-- @param table the table (object) to print
-- @param include a list of names to include
-- @param exclude a list of names to exclude
--
local function printObject( table, include, exclude, params )
	local indent = ""
	local step = 0
	local include = include or {}
	local exclude = exclude or {}
	local params = params or {}
	local options = {
		limit = 10,
	}
	opts = Utils.extend( params, options )

	--print("Printing object table =============================")
	function _print( t, ind, s )

		-- limit number of rounds
		if s > options.limit then return end

		for k, v in pairs( t ) do
			local ok_to_process = true

			if Utils.propertyIn( include, k ) then
				ok_to_process = true
			elseif type( t[k] ) == "function" or
				Utils.propertyIn( exclude, k ) or
				type( k ) == "string" and k:sub(1,1) == '_' then
				ok_to_process = false
			end

			if ok_to_process then

				if type( t[ k ] ) == "table" then
					local  o = t[ k ]
					local address = tostring( o )
					local items = #o
					print ( ind .. k .. " --> " .. address .. " w " .. items .. " items" )
					_print( t[ k ], ( ind .. "  " ), ( s + 1 ) )

				else
					if type( v ) == "string" then
						print ( ind ..  k .. " = '" .. v .. "'" )
					else
						print ( ind ..  k .. " = " .. tostring( v ) )
					end

				end
			end

		end
	end

	-- start printing process
	_print( table, indent, step + 1 )

end


-- indexFunc()
-- override the normal Lua lookup functionality to allow
-- property getter functions
--
-- @param t object table
-- @param k key
--
local function indexFunc( t, k )

	local o, val

	--== do key lookup in different places on object

	-- check for key in getters table
	o = rawget( t, '__getters' ) or {}
	if o[k] then return o[k](t) end

	-- check for key directly on object
	val = rawget( t, k )
	if val ~= nil then return val end

	-- check OO hierarchy
	o = rawget( t, '__parent' )
	if o then val = o[k] end
	if val ~= nil then return val end

	-- check object's view
	--[[
	o = rawget( t, 'view' )
	if o ~= nil and o[k] ~= nil then
		print("on view ", type(o[k]), o.x, k, o )
		if type(o[k]) == 'function' then
			return o[k]()
		else
			return o[k]
		end
	end
	--]]

	return nil
end

-- newindexFunc()
-- override the normal Lua lookup functionality to allow
-- property setter functions
--
-- @param t object table
-- @param k key
-- @param v value
--
local function newindexFunc( t, k, v )

	local o, f

	-- check for key in setters table
	o = rawget( t, '__setters' ) or {}
	f = o[k]
	if f then
		-- found setter, so call it
		f(t,v)
	else
		-- place key/value directly on object
		rawset( t, k, v )
	end

end

-- _bless()
-- sets up the inheritance chain via metatables
-- creates object to bless if one isn't provided
--
-- @param base base class object (optional)
-- @param obj object to bless (optional)
-- @return a blessed object
--
local function bless( base, obj )
	local o = obj or {}
	local mt = {
		__index = indexFunc,
		__newindex = newindexFunc,
	}
	if base and base[ CONSTRUCTOR_FUNC_NAME ] and type(base[ CONSTRUCTOR_FUNC_NAME])=='function' then
		mt.__call = base[ CONSTRUCTOR_FUNC_NAME ]
	end
	setmetatable( o, mt )

	-- create lookup tables - parent, setter, getter
	o.__parent = base
	o.__setters = {}
	o.__getters = {}
	if base then
		-- we have a parent, so let's copy down all its getters/setters
		o.__getters = Utils.extend( base.__getters, o.__getters )
		o.__setters = Utils.extend( base.__setters, o.__setters )
	end

	return o
end


local function inheritsFrom( baseClass, options, constructor )

	local constructor = constructor
	local o

	-- flag to indicate this is a subclass object
	-- will be set in the regular constructor
	options = options or {}
	options.__setIntermediate = true

	-- get default constructor
	if baseClass and constructor == nil then
		constructor = baseClass[ CONSTRUCTOR_FUNC_NAME ]
	end

	-- create our class object
	if baseClass == nil or constructor == nil then
		o = bless( baseClass )
	else
		o = constructor( baseClass, options )
	end


	--== Setup some class-type functions

	-- Return the class object of the instance
	function o:class()
		return o
	end

	-- Return the super class object of the instance
	function o:superClass()
		return baseClass
	end
	-- Return true if the caller is an instance of theClass
	function o:isa( theClass )
		local b_isa = false

		local cur_class = o

		while ( nil ~= cur_class ) and ( false == b_isa ) do
			if cur_class == theClass then
				 b_isa = true
			else
				 cur_class = cur_class:superClass()
			end
		end

		return b_isa
	end


	return o
end



--====================================================================--
-- Base Class
--====================================================================--

local ClassBase = inheritsFrom( nil )
ClassBase.NAME = "Class Base"

ClassBase._PRINT_INCLUDE = {}
ClassBase._PRINT_EXCLUDE = { '__dmc_super' }


-- new()
-- class constructor
--
function ClassBase:new( options )
	return self:_bless()
end


-- _bless()
-- interface to generic bless()
--
function ClassBase:_bless( obj )
	return bless( self, obj )
end


-- superCall( name, ... )
-- call a method on an object's parent
--
function ClassBase:superCall( name, ... )
	-- print( 'ClassBase:supercall', name, self.NAME )

	local c, s 		-- class, super
	local result
	local self_dmc_super = self.__dmc_super
	local super_flag = self_dmc_super

	-- finds method in class hierarchy
	-- returns found class or nil
	function findMethod( class, method )
		while class do
			if rawget( class, method ) then break end
			class = class:superClass()
		end
		return class
	end

	-- structure in which to save our place
	-- in case supercall is invoked again
	if self_dmc_super == nil then
		self.__dmc_super = {} -- a stack
		self_dmc_super = self.__dmc_super
		-- here we start with our class
		s = findMethod( self:class(), name )
		table.insert( self_dmc_super, s )
	end

	c = self_dmc_super[ # self_dmc_super ]
	-- here we start with the super class
	s = findMethod( c:superClass(), name )
	if s then
		table.insert( self_dmc_super, s )
		result = s[name]( self, unpack( arg ) )
		table.remove( self_dmc_super, # self_dmc_super )
	end

	-- here were the first and last on callstack, so clean up
	if super_flag == nil then
		table.remove( self_dmc_super, # self_dmc_super )
		self.__dmc_super = nil
	end

	return result
end


-- print
--
function ClassBase:print( include, exclude )
	local include = include or self._PRINT_INCLUDE
	local exclude = exclude or self._PRINT_EXCLUDE

	printObject( self, include, exclude )
end


function ClassBase:optimize()

	function _optimize( obj, class )

		-- climb up the hierarchy
		if not class then return end
		_optimize( obj, class:superClass() )

		-- make local references to all functions
		for k,v in pairs( class ) do
			if type( v ) == "function" then
				obj[ k ] = v
			end
		end

	end

	_optimize( self, self:class() )
end

function ClassBase:deoptimize()
	for k,v in pairs( self ) do
		if type( v ) == "function" then
			self[ k ] = nil
		end
	end
end


-- TODO: method can be a string or method reference
function ClassBase:createCallback( method )
	if method == nil then
		error( "ERROR: missing method in createCallback()", 2 )
	end
	return function( ... )
		return method( self, ... )
	end
end



--====================================================================--
-- Object Base Class
--====================================================================--

local ObjectBase = inheritsFrom( ClassBase )
ObjectBase.NAME = "Object Base"

--== Class Constants

ObjectBase.DMC_EVENT_DISPATCH = 'dmc_event_style_dispatch'
ObjectBase.CORONA_EVENT_DISPATCH = 'corona_event_style_dispatch'


--====================================================================--
-- Class Support Functions

-- callback is either function or object (table)
-- creates lookup key given event name and handler
--
local function createEventListenerKey( e_name, handler )
	return e_name .. "::" .. tostring( handler )
end


--====================================================================--
--== Constructor

-- this is the flow for DMC-style objects
-- typically, you won't override this
--
function ObjectBase:new( params )
	params = params or {}
	--==--

	local o = self:_bless()

	-- set flag if this is an Intermediate class
	if params.__setIntermediate == true then
		o.is_intermediate = true
		params.__setIntermediate = nil
	else
		o.is_intermediate = false
	end

	o:_init( params )

	-- skip these if we're an intermediate class (eg, subclass)
	if rawget( o, 'is_intermediate' ) == false then
		o:_initComplete()
	end

	return o
end


--====================================================================--
--== Start: Setup DMC Objects

-- _init()
-- initialize the object - setting the view
--
function ObjectBase:_init( options )
	-- OVERRIDE THIS
	--== Create Properties ==--
	self.__event_listeners = {} -- holds event listeners
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
	--== Object References ==--
end
-- _undoInit()
-- remove items added during _init()
--
function ObjectBase:_undoInit( options )
	-- OVERRIDE THIS
	self.__event_listeners = nil
end


-- _initComplete()
-- any setup after object is done being created
--
function ObjectBase:_initComplete()
	-- OVERRIDE THIS

	self:_setDispatchType( ObjectBase.DMC_EVENT_DISPATCH )
end
-- _undoInitComplete()
-- remove any items added during _initComplete()
--
function ObjectBase:_undoInitComplete()
	-- OVERRIDE THIS
end

--== END: Setup DMC Objects
--====================================================================--



--====================================================================--
--== Public Methods

-- addEventListener()
--
function ObjectBase:addEventListener( e_name, listener )
	-- print( "ObjectBase:addEventListener", e_name, listener );

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

	key = createEventListenerKey( e_name, listener )
	if listeners[ key ] then
		print("WARNING:: ObjectBase:addEventListener, already have listener")
	else
		listeners[ key ] = listener
	end

end


-- removeEventListener()
--
function ObjectBase:removeEventListener( e_name, listener )
	-- print( "ObjectBase:removeEventListener" );

	local listeners, key

	listeners = self.__event_listeners[ e_name ]
	if not listeners or type(listeners)~= 'table' then
		print("WARNING:: ObjectBase:removeEventListener, no listeners found")
	end

	key = createEventListenerKey( e_name, listener )

	if not listeners[ key ] then
		print("WARNING:: ObjectBase:removeEventListener, listener not found")
	else
		listeners[ key ] = nil
	end

end


-- removeSelf()
--
function ObjectBase:removeSelf()
	-- print( "ObjectBase:removeSelf" );

	-- skip these if we're an intermediate class (eg, subclass)
	if rawget( self, 'is_intermediate' ) == false then
		self:_undoInitComplete()
	end

	self:_undoInit()
end


--====================================================================--
--== Private Methods

-- _corona_dispatchEvent( event, params )
--
function ObjectBase:_corona_dispatchEvent( event, params )
	-- print( "ObjectBase:_corona_dispatchEvent", e_type );
	params = params or {}
	if params.merge == nil then params.merge = false end
	--==--
	self:_dispatchEvent( event )
end


-- _dmc_dispatchEvent( event, data, params )
--
function ObjectBase:_dmc_dispatchEvent( e_type, data, params )
	-- print( "ObjectBase:_dmc_dispatchEvent", e_type );
	params = params or {}
	if params.merge == nil then params.merge = true end
	--==--
	local e

	if params.merge and type( data ) == 'table' then
		e = data
		e.name = self.EVENT
		e.type = e_type
		e.target = self

	else
		e = {
			name=self.EVENT,
			type=e_type,
			target=self,
			data=data
		}

	end

	self:_dispatchEvent( e )
end


function ObjectBase:_dispatchEvent( event )
	-- print( "ObjectBase:_dispatchEvent", event.name );
	local e_name, listeners

	e_name = event.name
	if not e_name or not self.__event_listeners[ e_name ] then return end

	listeners = self.__event_listeners[ e_name ]
	if type(listeners)~='table' then return end

	for k, callback in pairs( listeners ) do

		if type( callback) == 'function' then
		 	callback( event )

		elseif type( callback )=='table' and callback[e_name] then
			local method = callback[e_name]
			method( callback, event )

		else
			print( "WARNING: ObjectBase dispatchEvent", e_name )

		end
	end
end


-- _setDispatchType
function ObjectBase:_setDispatchType( dispatch_type )
	-- print( "ObjectBase:_setDispatchType", dispatch_type );

	if dispatch_type == ObjectBase.CORONA_EVENT_DISPATCH then
		self.dispatchEvent = ObjectBase._corona_dispatchEvent
	else
		self.dispatchEvent = ObjectBase._dmc_dispatchEvent
	end

end


--====================================================================--
--== Event Handlers

-- none






--====================================================================--
-- Lua Objects Exports
--====================================================================--

return {
	setConstructorName = setConstructorName,
	inheritsFrom = inheritsFrom,
	ClassBase = ClassBase,
	ObjectBase = ObjectBase
}

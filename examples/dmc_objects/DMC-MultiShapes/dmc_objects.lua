
--====================================================================--
-- dmc_objects.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_objects.lua
--====================================================================--

--[[

Copyright (C) 2011 David McCuskey. All Rights Reserved.

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


-- =========================================================
-- Imports
-- =========================================================

local Utils = require( "dmc_utils" )



-- =========================================================
-- Class Support Functions
-- =========================================================

--
-- indexFunc()
-- override the normal Lua lookup functionality to allow
-- property getter functions
--
local function indexFunc( t, k )

	local gt, f, val, par

	-- look for key in getters table
	gt = rawget( t, '__getters' ) or {}
	f = gt[ k ]
	if f then
		-- found getter function, let's call it
		val = f( t )
	else
		-- not in getter, so check for key directly on object
		val = rawget( t, k )
		if val == nil then
			-- not found on object, so let's check parent hierarchy
			par = rawget( t, '__parent' )
			if par then val = par[ k ] end
		end
	end

	return val
end

-- newindexFunc()
-- override the normal Lua lookup functionality to allow
-- property setter functions
--
local function newindexFunc( t, k, v )

	local st, f

	-- look for key in setters table
	st = rawget( t, '__setters' ) or {}
	f = st[ k ]
	if f then
		-- found setter function, let's call it
		f( t, v )
	else
		-- not in setter, so place key/value directly on object
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
		__newindex = newindexFunc
	}
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

	-- get default constructor
	if baseClass and constructor == nil then
		constructor = baseClass['new']	-- assuming new
	end

	-- create our class object
	if baseClass == nil or constructor == nil then
		o = bless( baseClass )
	else
		o = constructor( baseClass, options )
	end


	-- Setup some class type functions

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




-- =========================================================
-- Object Class
-- =========================================================


local Object = inheritsFrom( nil )
Object.NAME = "Object Base"

Object._PRINT_INCLUDE = {}
Object._PRINT_EXCLUDE = { '__dmc_super' }



-- new()
-- class constructor
--
function Object:new( options )
	return self:_bless()
end


-- _bless()
-- interface to generic bless()
--
function Object:_bless( obj )
	return bless( self, obj )
end


-- superCall( name, ... )
-- call a method on an object's parent
--
function Object:superCall( name, ... )

	local c, s 		-- class, super
	local found		-- flag, if property is found
	local result
	local self_dmc_super = self.__dmc_super
	local super_flag = self_dmc_super

	-- structure in which to save our place
	-- in case supercall is invoked again
	if self_dmc_super == nil then
		self.__dmc_super = {} -- a stack
		self_dmc_super = self.__dmc_super
		table.insert( self_dmc_super, self )
	end

	-- loop setup
	c = self_dmc_super[ # self_dmc_super ]
	s = c:superClass()
	found = false

	-- loop through class supers and their properties
	-- until we find first match
	while s and not found do
		found = rawget( s, name )
		if found then
			-- push the stack, call the method, pop the stack
			table.insert( self_dmc_super, s )
			result = s[name]( self, unpack( arg ) )
			table.remove( self_dmc_super, # self_dmc_super )
		end
		s = s:superClass()
	end

	-- we were the first and last, so clean up
	if super_flag == nil then
		table.remove( self_dmc_super, # self_dmc_super )
		self.__dmc_super = nil
	end

	return result
end


-- print
-- convenience method to interface with Utils.print
--
function Object:print( include, exclude )
	local include = include or self._PRINT_INCLUDE
	local exclude = exclude or self._PRINT_EXCLUDE

	Utils.print( self, include, exclude )
end



function Object:optimize()

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

function Object:deoptimize()
	for k,v in pairs( self ) do
		if type( v ) == "function" then
			self[ k ] = nil
		end
	end
end




-- =========================================================
-- CoronaBase Class
-- =========================================================


local CoronaBase = inheritsFrom( Object )
CoronaBase.NAME = "Corona Base"


-- new()
-- class constructor
--
function CoronaBase:new( options )

	local o = self:_bless()
	o:_init( options )
	o:_createView()

	return o
end


-- _init()
-- initialize the object by taking on options and setting the display
--
function CoronaBase:_init( options )

	-- add new properties specific to our class
	self.display = nil

	-- add passed in properties
	if options then Utils.extend( options, self ) end

	-- create our class display container
	local d = self:_createDisplay()
	self:_setDisplay( d )

end


-- _createView()
-- method where any visual items specific to object are created
-- they are then put into the Corona display object
--
function CoronaBase:_createView()
	-- OVERRIDE THIS
end


-- _createDisplay()
-- create and return the root display object
--
function CoronaBase:_createDisplay()
	return display.newGroup()
end


-- _setDisplay( obj )
-- set the object to the display property
--
function CoronaBase:_setDisplay( obj )
	self.display = obj
end


-- destroy()
-- remove the display object from the stage
--
function CoronaBase:destroy()
	self.display:removeSelf()
	self.display = nil
end


-- Getters and Setters


function CoronaBase.__getters:x()
	return self.display.x
end
function CoronaBase.__setters:x( value )
	self.display.x = value
end
function CoronaBase.__getters:y()
	return self.display.y
end
function CoronaBase.__setters:y( value )
	self.display.y = value
end

function CoronaBase.__getters:stageBounds()
	return self.display.stageBounds
end
function CoronaBase.__getters:contentBounds()
	return self.display.contentBounds
end



function CoronaBase:show()
	self.display.isVisible = true
end
function CoronaBase:hide()
	self.display.isVisible = false
end
function CoronaBase:setWidth( value )
	self.display.width = value
end
function CoronaBase:setHeight( value )
	self.display.height = value
end
function CoronaBase:translate( x, y )
	self.display:translate( x, y )
end
function CoronaBase:scale( x, y )
	self.display:scale( x, y )
end
function CoronaBase:insert( obj )
	self.display:insert( obj )
end
function CoronaBase:remove( obj )
	self.display:remove( obj )
end
function CoronaBase:addEventListener( obj, func )
	self.display:addEventListener( obj, func )
end
function CoronaBase:removeEventListener( obj, func )
	self.display:removeEventListener( obj, func )
end
function CoronaBase:dispatchEvent( event )
	self.display:dispatchEvent( event )
end
function CoronaBase:setReferencePoint( reference )
	self.display:setReferencePoint( reference )
end




-- =========================================================
-- CoronaPhysics Class
-- =========================================================


local CoronaPhysics = inheritsFrom( CoronaBase )
CoronaPhysics.NAME = "Corona Physics"


-- Getters and Setters

function CoronaBase.__getters:isAwake()
	return self.display.isAwake
end
function CoronaBase.__getters:isBodyActive()
	return self.display.isBodyActive
end
function CoronaBase.__getters:isBullet()
	return self.display.isBullet
end
function CoronaBase.__getters:isSensor()
	return self.display.isSensor
end
function CoronaBase.__getters:isSleepingAllowed()
	return self.display.isSleepingAllowed
end
function CoronaBase.__getters:isFixedRotation()
	return self.display.isFixedRotation
end
function CoronaBase.__getters:angularVelocity()
	return self.display.angularVelocity
end
function CoronaBase.__getters:linearDamping()
	return self.display.linearDamping
end
function CoronaBase.__getters:angularDamping()
	return self.display.angularDamping
end
function CoronaBase.__getters:bodyType()
	return self.display.bodyType
end


-- Methods

function CoronaBase:setLinearVelocity( Vx, Vy )
	self.display:setLinearVelocity( Vx, Vy )
end
function CoronaBase:getLinearVelocity()
	return self.display:getLinearVelocity()
end
function CoronaBase:applyForce( Fx, Fy, Px, Py )
	self.display:applyForce( Fx, Fy, Px, Py )
end
function CoronaBase:applyTorque( force )
	self.display:applyTorque( force )
end
function CoronaBase:applyLinearImpulse( Fx, Fy, Px, Py )
	self.display:applyLinearImpulse( Fx, Fy, Px, Py )
end
function CoronaBase:applyAngularImpulse( force )
	self.display:applyAngularImpulse( force )
end
function CoronaBase:resetMassData()
	self.display:resetMassData()
end



-- =========================================================
-- DMC Objects Exports
-- =========================================================


local Objects = {
	inheritsFrom = inheritsFrom,
	Object = Object,
	CoronaBase = CoronaBase,
	CoronaPhysics = CoronaPhysics,
}


return Objects

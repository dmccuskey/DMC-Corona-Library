
--====================================================================--
-- dmc_objects.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_objects.lua
--====================================================================--

--[[

Copyright (C) 2011-2013 David McCuskey. All Rights Reserved.

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

local VERSION = "1.0.2"


-- =========================================================
-- Imports
-- =========================================================




-- =========================================================
-- Class Support Functions
-- =========================================================


-- propertyIn()
-- Determines whether a property is within a list of items in a table (acting as an array)
--
-- @param table the table with *list* of properties
-- @param property the name of the property to search for
--
local function propertyIn( list, property )
  for i = 1, #list do
    if list[i] == property then return true end
  end
  return false
end


-- extend()
-- Copy key/values from one table to another
-- Will deep copy any value from first table which is itself a table.
--
-- @param fromTable the table (object) from which to take key/value pairs
-- @param toTable the table (object) in which to copy key/value pairs
-- @return table the table (object) that received the copied items
--
local function extend( fromTable, toTable )

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
	opts = extend( params, options )

	--print("Printing object table =============================")
	function _print( t, ind, s )

		-- limit number of rounds
		if s > options.limit then return end

		for k, v in pairs( t ) do
			local ok_to_process = true

			if propertyIn( include, k ) then
				ok_to_process = true
			elseif type( t[k] ) == "function" or
				propertyIn( exclude, k ) or
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
		o.__getters = extend( base.__getters, o.__getters )
		o.__setters = extend( base.__setters, o.__setters )
	end

	return o
end


local function inheritsFrom( baseClass, options, constructor )

	local constructor = constructor
	local o

	-- flag to indicate this is a subclass object
	-- will be set in the constructor
	options = options or {}
	options.__setIntermediate = true

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
--
function Object:print( include, exclude )
	local include = include or self._PRINT_INCLUDE
	local exclude = exclude or self._PRINT_EXCLUDE

	printObject( self, include, exclude )
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



-- TODO: method can be a string or method reference
function Object:createCallback( method )
	return function( ... )
		method( self, ... )
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

	options = options or {}

	local o = self:_bless()

	-- set flag if this is an Intermediate class
	if options.__setIntermediate == true then
		o.__isIntermediate = true
		options.__setIntermediate = nil
	end

	o:_init( options )

	-- skip these if we're an intermediate class (eg, subclass)
	if rawget( o, '__isIntermediate' ) == nil then
		o:_createView()
		o:_initComplete()
	end

	return o
end


-- _init()
-- initialize the object - setting the view
--
function CoronaBase:_init( options )
	-- OVERRIDE THIS

	--== Create Properties ==--
	--== Display Groups ==--
	--== Object References ==--

	-- create our class view container
	self:_setView( display.newGroup() )

end
-- _undoInit()
-- remove items added during _init()
--
function CoronaBase:_undoInit( options )
	-- OVERRIDE THIS
	self:_unsetView()
end


-- _createView()
-- create any visual items specific to object
--
function CoronaBase:_createView()
	-- OVERRIDE THIS
end
-- _undoCreateView()
-- remove any items added during _createView()
--
function CoronaBase:_undoCreateView()
	-- OVERRIDE THIS
end


-- _initComplete()
-- any setup after object is done being created
--
function CoronaBase:_initComplete()
	-- OVERRIDE THIS
end
-- _undoInitComplete()
-- remove any items added during _initComplete()
--
function CoronaBase:_undoInitComplete()
	-- OVERRIDE THIS
end


-- _setView( viewObject )
-- set the view property to incoming view object
-- remove current if already set, only check direct property, not hierarchy
--
function CoronaBase:_setView( viewObject )
	self:_unsetView()

	self.view = viewObject
	self.display = self.view
	-- save ref of our Lua object on Corona element
	-- in case we need to get back to the object
	self.view.__dmc_ref = self
end
-- _unsetView()
-- remove the view property
--
function CoronaBase:_unsetView()
	if rawget( self, 'view' ) ~= nil then
		local view = self.view

		if view.__dmc_ref then view.__dmc_ref = nil end

		if view.numChildren ~= nil then
			for i = view.numChildren, 1, -1 do
				local o = view[i]
				o.parent:remove( o )
			end		
		end
		view:removeSelf()
		self.view = nil
		self.display = nil
	end
end


-- destroy()
-- remove the view object from the stage
--
function CoronaBase:destroy()
	self:removeSelf()
end


function CoronaBase:show()
	self.view.isVisible = true
end
function CoronaBase:hide()
	self.view.isVisible = false
end


--== Corona Specific Properties and Methods ==--


--= DISPLAY GROUP =--

-- Properties --

-- numChildren
--
function CoronaBase.__getters:numChildren()
	return self.view.numChildren
end


-- Methods --

-- insert( [index,] child, [, resetTransform]  )
--
function CoronaBase:insert( ... )
	self.view:insert( ... )
end
-- remove( indexOrChild )
--
function CoronaBase:remove( ... )
	self.view:remove( ... )
end



--= CORONA OBJECT =--

-- Properties

-- alpha
--
function CoronaBase.__getters:alpha()
	return self.view.alpha
end
function CoronaBase.__setters:alpha( value )
	self.view.alpha = value
end
-- contentBounds
--
function CoronaBase.__getters:contentBounds()
	return self.view.contentBounds
end
-- contentHeight
--
function CoronaBase.__getters:contentHeight()
	return self.view.contentHeight
end
-- contentWidth
--
function CoronaBase.__getters:contentWidth()
	return self.view.contentWidth
end
-- height
--
function CoronaBase.__getters:height()
	return self.view.height
end
function CoronaBase.__setters:height( value )
	self.view.height = value
end
-- isHitTestMasked
--
function CoronaBase.__getters:isHitTestMasked()
	return self.view.isHitTestMasked
end
function CoronaBase.__setters:isHitTestMasked( value )
	self.view.isHitTestMasked = value
end
-- isHitTestable
--
function CoronaBase.__getters:isHitTestable()
	return self.view.isHitTestable
end
function CoronaBase.__setters:isHitTestable( value )
	self.view.isHitTestable = value
end
-- isVisible
--
function CoronaBase.__getters:isVisible()
	return self.view.isVisible
end
function CoronaBase.__setters:isVisible( value )
	self.view.isVisible = value
end
-- maskRotation
--
function CoronaBase.__getters:maskRotation()
	return self.view.maskRotation
end
function CoronaBase.__setters:maskRotation( value )
	self.view.maskRotation = value
end
-- maskScaleX
--
function CoronaBase.__getters:maskScaleX()
	return self.view.maskScaleX
end
function CoronaBase.__setters:maskScaleX( value )
	self.view.maskScaleX = value
end
-- maskScaleY
--
function CoronaBase.__getters:maskScaleY()
	return self.view.maskScaleY
end
function CoronaBase.__setters:maskScaleY( value )
	self.view.maskScaleY = value
end
-- maskX
--
function CoronaBase.__getters:maskX()
	return self.view.maskX
end
function CoronaBase.__setters:maskX( value )
	self.view.maskX = value
end
-- maskY
--
function CoronaBase.__getters:maskY()
	return self.view.maskY
end
function CoronaBase.__setters:maskY( value )
	self.view.maskY = value
end
-- parent
--
function CoronaBase.__getters:parent()
	return self.view.parent
end
-- rotation
--
function CoronaBase.__getters:rotation()
	return self.view.rotation
end
function CoronaBase.__setters:rotation( value )
	self.view.rotation = value
end
-- stageBounds
--
function CoronaBase.__getters:stageBounds()
	print( "\nDEPRECATED: object.stageBounds - use object.contentBounds\n" )
	return self.view.stageBounds
end
-- width
--
function CoronaBase.__getters:width()
	return self.view.width
end
function CoronaBase.__setters:width( value )
	self.view.width = value
end
-- x
--
function CoronaBase.__getters:x()
	return self.view.x
end
function CoronaBase.__setters:x( value )
	self.view.x = value
end
-- xOrigin
--
function CoronaBase.__getters:xOrigin()
	return self.view.xOrigin
end
function CoronaBase.__setters:xOrigin( value )
	self.view.xOrigin = value
end
-- xReference
--
function CoronaBase.__getters:xReference()
	return self.view.xReference
end
function CoronaBase.__setters:xReference( value )
	self.view.xReference = value
end
-- xScale
--
function CoronaBase.__getters:xScale()
	return self.view.xScale
end
function CoronaBase.__setters:xScale( value )
	self.view.xScale = value
end
-- y
--
function CoronaBase.__getters:y()
	return self.view.y
end
function CoronaBase.__setters:y( value )
	self.view.y = value
end
-- yOrigin
--
function CoronaBase.__getters:yOrigin()
	return self.view.yOrigin
end
function CoronaBase.__setters:yOrigin( value )
	self.view.yOrigin = value
end
-- yReference
--
function CoronaBase.__getters:yReference()
	return self.view.yReference
end
function CoronaBase.__setters:yReference( value )
	self.view.yReference = value
end
-- yScale
--
function CoronaBase.__getters:yScale()
	return self.view.yScale
end
function CoronaBase.__setters:yScale( value )
	self.view.yScale = value
end



-- Methods --

-- addEventListener( eventName, listener )
--
function CoronaBase:addEventListener( ... )
	self.view:addEventListener( ... )
end
-- contentToLocal( x_content, y_content )
--
function CoronaBase:contentToLocal( ... )
	self.view:contentToLocal( ... )
end
-- dispatchEvent( event )
--
function CoronaBase:dispatchEvent( ... )
	self.view:dispatchEvent( ... )
end
-- localToContent( x, y )
--
function CoronaBase:localToContent( ... )
	self.view:localToContent( ... )
end
-- removeEventListener( eventName, listener )
--
function CoronaBase:removeEventListener( ... )
	self.view:removeEventListener( ... )
end
-- removeSelf()
--
function CoronaBase:removeSelf()
	--print( "\nOVERRIDE: removeSelf()\n" );

	-- skip these if we're an intermediate class (eg, subclass)
	if rawget( self, '__isIntermediate' ) == nil then
		self:_undoInitComplete()
		self:_undoCreateView()
	end

	self:_undoInit()
end
-- rotate( deltaAngle )
--
function CoronaBase:rotate( ... )
	self.view:rotate( ... )
end
-- scale( sx, sy )
--
function CoronaBase:scale( ... )
	self.view:scale( ... )
end
function CoronaBase:setMask( ... )
	print( "\nWARNING: setMask( mask ) not tested \n" );
	self.view:setMask( ... )
end
-- setReferencePoint( referencePoint )
--
function CoronaBase:setReferencePoint( ... )
	self.view:setReferencePoint( ... )
end
-- toBack()
--
function CoronaBase:toBack()
	self.view:toBack()
end
-- toFront()
--
function CoronaBase:toFront()
	self.view:toFront()
end
-- translate( deltaX, deltaY )
--
function CoronaBase:translate( ... )
	self.view:translate( ... )
end






-- =========================================================
-- CoronaPhysics Class
-- =========================================================


local CoronaPhysics = inheritsFrom( CoronaBase )
CoronaPhysics.NAME = "Corona Physics"


-- Properties --


-- angularDamping()
--
function CoronaPhysics.__getters:angularDamping()
	return self.view.angularDamping
end
function CoronaPhysics.__setters:angularDamping( value )
	self.view.angularDamping = value
end
-- angularVelocity()
--
function CoronaPhysics.__getters:angularVelocity()
	return self.view.angularVelocity
end
function CoronaPhysics.__setters:angularVelocity( value )
	self.view.angularVelocity = value
end
-- bodyType()
--
function CoronaPhysics.__getters:bodyType()
	return self.view.bodyType
end
function CoronaPhysics.__setters:bodyType( value )
	self.view.bodyType = value
end
-- isAwake()
--
function CoronaPhysics.__getters:isAwake()
	return self.view.isAwake
end
function CoronaPhysics.__setters:isAwake( value )
	self.view.isAwake = value
end
-- isBodyActive()
--
function CoronaPhysics.__getters:isBodyActive()
	return self.view.isBodyActive
end
function CoronaPhysics.__setters:isBodyActive( value )
	self.view.isBodyActive = value
end
-- isBullet()
--
function CoronaPhysics.__getters:isBullet()
	return self.view.isBullet
end
function CoronaPhysics.__setters:isBullet( value )
	self.view.isBullet = value
end
-- isFixedRotation()
--
function CoronaPhysics.__getters:isFixedRotation()
	return self.view.isFixedRotation
end
function CoronaPhysics.__setters:isFixedRotation( value )
	self.view.isFixedRotation = value
end
-- isSensor()
--
function CoronaPhysics.__getters:isSensor()
	return self.view.isSensor
end
function CoronaPhysics.__setters:isSensor( value )
	self.view.isSensor = value
end
-- isSleepingAllowed()
--
function CoronaPhysics.__getters:isSleepingAllowed()
	return self.view.isSleepingAllowed
end
function CoronaPhysics.__setters:isSleepingAllowed( value )
	self.view.isSleepingAllowed = value
end
-- linearDamping()
--
function CoronaPhysics.__getters:linearDamping()
	return self.view.linearDamping
end
function CoronaPhysics.__setters:linearDamping( value )
	self.view.linearDamping = value
end


-- Methods --

-- applyAngularImpulse( appliedForce )
--
function CoronaPhysics:applyAngularImpulse( ... )
	self.view:applyAngularImpulse( ... )
end
-- applyForce( xForce, yForce, bodyX, bodyY )
--
function CoronaPhysics:applyForce( ... )
	self.view:applyForce( ... )
end
-- applyLinearImpulse( xForce, yForce, bodyX, bodyY )
--
function CoronaPhysics:applyLinearImpulse( ... )
	self.view:applyLinearImpulse( ... )
end
-- applyTorque( appliedForce )
--
function CoronaPhysics:applyTorque( ... )
	self.view:applyTorque( ... )
end
-- getLinearVelocity()
--
function CoronaPhysics:getLinearVelocity()
	return self.view:getLinearVelocity()
end
-- resetMassData()
--
function CoronaPhysics:resetMassData()
	self.view:resetMassData()
end
-- setLinearVelocity( xVelocity, yVelocity )
--
function CoronaPhysics:setLinearVelocity( ... )
	self.view:setLinearVelocity( ... )
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

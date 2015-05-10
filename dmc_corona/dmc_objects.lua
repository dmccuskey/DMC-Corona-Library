--====================================================================--
-- dmc_objects.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2011-2015 David McCuskey

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
--== DMC Corona Library : DMC Objects
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.1.2"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--


--====================================================================--
--== Support Functions


local Utils = {} -- make copying from Utils easier


--== Start: copy from lua_utils ==--

-- extend()
-- Copy key/values from one table to another
-- Will deep copy any value from first table which is itself a table.
--
-- @param fromTable the table (object) from which to take key/value pairs
-- @param toTable the table (object) in which to copy key/value pairs
-- @return table the table (object) that received the copied items
--
function Utils.extend( fromTable, toTable )

	if not fromTable or not toTable then
		error( "table can't be nil" )
	end
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

--== End: copy from lua_utils ==--



--====================================================================--
--== Configuration


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona



--====================================================================--
--== DMC Objects
--====================================================================--


--====================================================================--
--== Configuration


dmc_lib_data.dmc_objects = dmc_lib_data.dmc_objects or {}

local DMC_OBJECTS_DEFAULTS = {
}

local dmc_objects_data = Utils.extend( dmc_lib_data.dmc_objects, DMC_OBJECTS_DEFAULTS )



--====================================================================--
--== Imports


local Objects = require 'lib.dmc_lua.lua_objects'
local EventsMixModule = require 'lib.dmc_lua.lua_events_mix'



--====================================================================--
--== Setup, Constants


local Class = Objects.Class
local registerCtorName = Objects.registerCtorName
local registerDtorName = Objects.registerDtorName

local EventsMix = EventsMixModule.EventsMix


-- Add new Dtor name (function references)
registerDtorName( 'removeSelf', Class )



--====================================================================--
--== Support Functions


_G.getDMCObject = function( object )
	local ref = object
	if object.__dmc_ref then ref = object.__dmc_ref end
	return ref
end



--====================================================================--
--== Component Base Class
--====================================================================--


local ComponentBase = newClass( Objects.ObjectBase, { name="Component" } )


--== Class Constants ==--

--references for setAnchor()
ComponentBase.TopLeftReferencePoint = { 0, 0 }
ComponentBase.TopCenterReferencePoint = { 0.5, 0 }
ComponentBase.TopRightReferencePoint = { 1, 0 }
ComponentBase.CenterLeftReferencePoint = { 0, 0.5 }
ComponentBase.CenterReferencePoint = { 0.5, 0.5 }
ComponentBase.CenterRightReferencePoint = { 1, 0.5 }
ComponentBase.BottomLeftReferencePoint = { 0, 1 }
ComponentBase.BottomCenterReferencePoint = { 0.5, 1 }
ComponentBase.BottomRightReferencePoint = { 1, 1 }



--======================================================--
--== Constructor / Destructor


-- __new__()
-- this method drives the construction flow for DMC-style objects
-- typically, you won't override this
--
function ComponentBase:__new__( ... )

	--== Do setup sequence ==--

	self:__init__( ... )

	-- skip these if a Class object (ie, NOT an instance)
	if rawget( self, '__is_class' ) == false then
		self:__createView__()
		self:__initComplete__()
	end

	return self
end


-- __destroy__()
-- this method drives the destruction flow for DMC-style objects
-- typically, you won't override this
--
function ComponentBase:__destroy__()

	-- skip these if we're an intermediate class (eg, subclass)
	if rawget( self, '__is_class' ) == false then
		self:__undoInitComplete__()
		self:__undoCreateView__()
	end

	self:__undoInit__()

end


--======================================================--
-- Start: Setup DMC Objects

-- __init__()
-- initialize the object
--
function ComponentBase:__init__( ... )
	self:superCall( '__init__', ... )
	--==--
	self:_setView( display.newGroup() )
end

-- __undoInit__()
-- de-initialize the object
--
function ComponentBase:__undoInit__()
	self:_unsetView()
	--==--
	self:superCall( '__undoInit__' )
end


-- _createView()
-- create any visual items specific to object
--
function ComponentBase:__createView__()
	-- Subclasses should call:
	-- self:superCall( '__createView__' )
	--==--
end

-- _undoCreateView()
-- remove any items added during _createView()
--
function ComponentBase:__undoCreateView__()
	--==--
	-- Subclasses should call:
	-- self:superCall( '__undoCreateView__' )
end


--[[

-- __initComplete__()
-- do final setup after view creation
--
function ComponentBase:__initComplete__()
	self:superCall( '__initComplete__' )
	--==--
end

-- __undoInitComplete__()
-- remove final setup before view destruction
--
function ComponentBase:__undoInitComplete__()
	--==--
	self:superCall( '__undoInitComplete__' )
end

--]]

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


-- none



--====================================================================--
--== Private Methods


-- _setView( viewObject )
-- set the view property to incoming view object
-- remove current if already set, only check direct property, not hierarchy
--
function ComponentBase:_setView( viewObject )
	self:_unsetView()

	self.view = viewObject
	self.display = self.view -- deprecated
	-- save ref of our Lua object on Corona element
	-- in case we need to get back to the object
	self.view.__dmc_ref = self
end
-- _unsetView()
-- remove the view property
--
function ComponentBase:_unsetView()
	if rawget( self, 'view' ) ~= nil then
		local view = self.view

		if view.__dmc_ref then view.__dmc_ref = nil end

		if view.numChildren~=0 then
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



--====================================================================--
--== Public Methods / Corona API


function ComponentBase:setTouchBlock( o )
	assert( o, "setTouchBlock: expected object" )
	o.touch = function(e) return true end
	o:addEventListener( 'touch', o )
end
function ComponentBase:unsetTouchBlock( o )
	assert( o, "unsetTouchBlock: expected object" )
	if o and o.touch then
		o:removeEventListener( 'touch', o )
		o.touch = nil
	end
end



function ComponentBase.__setters:dispatch_type( value )
	self._dispatch_type = value
end


-- destroy()
-- remove the view object from the stage
--
function ComponentBase:destroy()
	self:removeSelf()
end

function ComponentBase:show()
	self.view.isVisible = true
end
function ComponentBase:hide()
	self.view.isVisible = false
end


--== Corona Specific Properties and Methods ==--


--= DISPLAY GROUP =--

-- Properties --

-- numChildren
--
function ComponentBase.__getters:numChildren()
	return self.view.numChildren
end


-- Methods --

-- insert( [index,] child, [, resetTransform]  )
--
function ComponentBase:insert( ... )
	self.view:insert( ... )
end
-- remove( indexOrChild )
--
function ComponentBase:remove( ... )
	self.view:remove( ... )
end


--= CORONA OBJECT =--

-- Properties

-- alpha
--
function ComponentBase.__getters:alpha()
	return self.view.alpha
end
function ComponentBase.__setters:alpha( value )
	self.view.alpha = value
end
-- contentBounds
--
function ComponentBase.__getters:contentBounds()
	return self.view.contentBounds
end
-- contentHeight
--
function ComponentBase.__getters:contentHeight()
	return self.view.contentHeight
end
-- contentWidth
--
function ComponentBase.__getters:contentWidth()
	return self.view.contentWidth
end
-- height
--
function ComponentBase.__getters:height()
	return self.view.height
end
function ComponentBase.__setters:height( value )
	self.view.height = value
end
-- isHitTestMasked
--
function ComponentBase.__getters:isHitTestMasked()
	return self.view.isHitTestMasked
end
function ComponentBase.__setters:isHitTestMasked( value )
	self.view.isHitTestMasked = value
end
-- isHitTestable
--
function ComponentBase.__getters:isHitTestable()
	return self.view.isHitTestable
end
function ComponentBase.__setters:isHitTestable( value )
	self.view.isHitTestable = value
end
-- isVisible
--
function ComponentBase.__getters:isVisible()
	return self.view.isVisible
end
function ComponentBase.__setters:isVisible( value )
	self.view.isVisible = value
end
-- maskRotation
--
function ComponentBase.__getters:maskRotation()
	return self.view.maskRotation
end
function ComponentBase.__setters:maskRotation( value )
	self.view.maskRotation = value
end
-- maskScaleX
--
function ComponentBase.__getters:maskScaleX()
	return self.view.maskScaleX
end
function ComponentBase.__setters:maskScaleX( value )
	self.view.maskScaleX = value
end
-- maskScaleY
--
function ComponentBase.__getters:maskScaleY()
	return self.view.maskScaleY
end
function ComponentBase.__setters:maskScaleY( value )
	self.view.maskScaleY = value
end
-- maskX
--
function ComponentBase.__getters:maskX()
	return self.view.maskX
end
function ComponentBase.__setters:maskX( value )
	self.view.maskX = value
end
-- maskY
--
function ComponentBase.__getters:maskY()
	return self.view.maskY
end
function ComponentBase.__setters:maskY( value )
	self.view.maskY = value
end
-- parent
--
function ComponentBase.__getters:parent()
	return self.view.parent
end
-- rotation
--
function ComponentBase.__getters:rotation()
	return self.view.rotation
end
function ComponentBase.__setters:rotation( value )
	self.view.rotation = value
end
-- stageBounds
--
function ComponentBase.__getters:stageBounds()
	print( "\nDEPRECATED: object.stageBounds - use object.contentBounds\n" )
	return self.view.stageBounds
end
-- width
--
function ComponentBase.__getters:width()
	return self.view.width
end
function ComponentBase.__setters:width( value )
	self.view.width = value
end
-- x
--
function ComponentBase.__getters:x()
	return self.view.x
end
function ComponentBase.__setters:x( value )
	self.view.x = value
end
-- xOrigin
--
function ComponentBase.__getters:xOrigin()
	return self.view.xOrigin
end
function ComponentBase.__setters:xOrigin( value )
	self.view.xOrigin = value
end
-- xReference
--
function ComponentBase.__getters:xReference()
	return self.view.xReference
end
function ComponentBase.__setters:xReference( value )
	self.view.xReference = value
end
-- xScale
--
function ComponentBase.__getters:xScale()
	return self.view.xScale
end
function ComponentBase.__setters:xScale( value )
	self.view.xScale = value
end
-- y
--
function ComponentBase.__getters:y()
	return self.view.y
end
function ComponentBase.__setters:y( value )
	self.view.y = value
end
-- yOrigin
--
function ComponentBase.__getters:yOrigin()
	return self.view.yOrigin
end
function ComponentBase.__setters:yOrigin( value )
	self.view.yOrigin = value
end
-- yReference
--
function ComponentBase.__getters:yReference()
	return self.view.yReference
end
function ComponentBase.__setters:yReference( value )
	self.view.yReference = value
end
-- yScale
--
function ComponentBase.__getters:yScale()
	return self.view.yScale
end
function ComponentBase.__setters:yScale( value )
	self.view.yScale = value
end


-- Methods --

-- addEventListener( eventName, listener )
--
function ComponentBase:addEventListener( ... )
	self.view:addEventListener( ... )
end

-- contentToLocal( x_content, y_content )
--
function ComponentBase:contentToLocal( ... )
	return self.view:contentToLocal( ... )
end


-- dispatchEvent( event )
-- can dispatch corona-style or dmc-style
-- corona style, just pass in event table structure
-- dmc-style, dispatchEvent( event-type, data (opt), params (opt) )
-- params:
-- event type (eg, 'button-changed-event')
-- event data, any type of data (eg, object, string, number, table, etc)
-- event params (optional, if have, must have arg for data (nil))
-- params.merge merge data into event table, default 'true'
function ComponentBase:dispatchEvent( ... )
	local args = {...}
	local evt = args[1]
	if type(evt)=='table' and type(evt.name)=='string' then
		-- corona type event
		-- we don't need to update anything
	else
		evt = EventsMixModule.dmcEventFunc( self, ... )
	end
	self.view:dispatchEvent( evt )
end

-- localToContent( x, y )
--
function ComponentBase:localToContent( ... )
	return self.view:localToContent( ... )
end

-- removeEventListener( eventName, listener )
--
function ComponentBase:removeEventListener( ... )
	self.view:removeEventListener( ... )
end

-- rotate( deltaAngle )
--
function ComponentBase:rotate( ... )
	self.view:rotate( ... )
end
-- scale( sx, sy )
--
function ComponentBase:scale( ... )
	self.view:scale( ... )
end

-- setAnchor
--
function ComponentBase:setAnchor( ... )
	local args = {...}
	if type( args[2] ) == 'table' then
		self.view.anchorX, self.view.anchorY = unpack( args[2] )
	end
	if type( args[2] ) == 'number' then
		self.view.anchorX = args[2]
	end
	if type( args[3] ) == 'number' then
		self.view.anchorY = args[3]
	end
end
function ComponentBase:setMask( ... )
	print( "\nWARNING: setMask( mask ) not tested \n" );
	self.view:setMask( ... )
end
-- setReferencePoint( referencePoint )
--
function ComponentBase:setReferencePoint( ... )
	self.view:setReferencePoint( ... )
end
-- toBack()
--
function ComponentBase:toBack()
	self.view:toBack()
end
-- toFront()
--
function ComponentBase:toFront()
	self.view:toFront()
end
-- translate( deltaX, deltaY )
--
function ComponentBase:translate( ... )
	self.view:translate( ... )
end




--====================================================================--
--== PhysicsComponentBase Class
--====================================================================--


local PhysicsComponentBase = newClass( ComponentBase, {name="Physics Component"})


-- Properties --

-- angularDamping()
--
function PhysicsComponentBase.__getters:angularDamping()
	return self.view.angularDamping
end
function PhysicsComponentBase.__setters:angularDamping( value )
	self.view.angularDamping = value
end
-- angularVelocity()
--
function PhysicsComponentBase.__getters:angularVelocity()
	return self.view.angularVelocity
end
function PhysicsComponentBase.__setters:angularVelocity( value )
	self.view.angularVelocity = value
end
-- bodyType()
--
function PhysicsComponentBase.__getters:bodyType()
	return self.view.bodyType
end
function PhysicsComponentBase.__setters:bodyType( value )
	self.view.bodyType = value
end
-- isAwake()
--
function PhysicsComponentBase.__getters:isAwake()
	return self.view.isAwake
end
function PhysicsComponentBase.__setters:isAwake( value )
	self.view.isAwake = value
end
-- isBodyActive()
--
function PhysicsComponentBase.__getters:isBodyActive()
	return self.view.isBodyActive
end
function PhysicsComponentBase.__setters:isBodyActive( value )
	self.view.isBodyActive = value
end
-- isBullet()
--
function PhysicsComponentBase.__getters:isBullet()
	return self.view.isBullet
end
function PhysicsComponentBase.__setters:isBullet( value )
	self.view.isBullet = value
end
-- isFixedRotation()
--
function PhysicsComponentBase.__getters:isFixedRotation()
	return self.view.isFixedRotation
end
function PhysicsComponentBase.__setters:isFixedRotation( value )
	self.view.isFixedRotation = value
end
-- isSensor()
--
function PhysicsComponentBase.__getters:isSensor()
	return self.view.isSensor
end
function PhysicsComponentBase.__setters:isSensor( value )
	self.view.isSensor = value
end
-- isSleepingAllowed()
--
function PhysicsComponentBase.__getters:isSleepingAllowed()
	return self.view.isSleepingAllowed
end
function PhysicsComponentBase.__setters:isSleepingAllowed( value )
	self.view.isSleepingAllowed = value
end
-- linearDamping()
--
function PhysicsComponentBase.__getters:linearDamping()
	return self.view.linearDamping
end
function PhysicsComponentBase.__setters:linearDamping( value )
	self.view.linearDamping = value
end


-- Methods --

-- applyAngularImpulse( appliedForce )
--
function PhysicsComponentBase:applyAngularImpulse( ... )
	self.view:applyAngularImpulse( ... )
end
-- applyForce( xForce, yForce, bodyX, bodyY )
--
function PhysicsComponentBase:applyForce( ... )
	self.view:applyForce( ... )
end
-- applyLinearImpulse( xForce, yForce, bodyX, bodyY )
--
function PhysicsComponentBase:applyLinearImpulse( ... )
	self.view:applyLinearImpulse( ... )
end
-- applyTorque( appliedForce )
--
function PhysicsComponentBase:applyTorque( ... )
	self.view:applyTorque( ... )
end
-- getLinearVelocity()
--
function PhysicsComponentBase:getLinearVelocity()
	return self.view:getLinearVelocity()
end
-- resetMassData()
--
function PhysicsComponentBase:resetMassData()
	self.view:resetMassData()
end
-- setLinearVelocity( xVelocity, yVelocity )
--
function PhysicsComponentBase:setLinearVelocity( ... )
	self.view:setLinearVelocity( ... )
end




--====================================================================--
--== DMC Objects Exports
--====================================================================--


-- simply add to current exports
Objects.ComponentBase = ComponentBase
Objects.PhysicsComponentBase = PhysicsComponentBase



return Objects


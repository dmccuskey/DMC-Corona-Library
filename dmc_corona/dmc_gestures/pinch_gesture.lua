--====================================================================--
-- dmc_corona/dmc_gesture/pinch_gesture.lua
--
-- Documentation: http://docs.davidmccuskey.com/dmc-gestures
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2015 David McCuskey

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


--- Pinch Gesture Module
-- @module PinchGesture
-- @usage local Gesture = require 'dmc_gestures'
-- local view = display.newRect( 100, 100, 200, 200 )
-- local g = Gesture.newPinchGesture( view )
-- g:addEventListener( g.EVENT, gHandler )


--====================================================================--
--== DMC Corona Library : Pinch Gesture
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Pinch Gesture
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local Continuous = require 'dmc_gestures.core.continuous_gesture'
local Constants = require 'dmc_gestures.gesture_constants'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass

local mabs = math.abs
local msqrt = math.sqrt
local tinsert = table.insert
local tremove = table.remove



--====================================================================--
--== Pinch Gesture Class
--====================================================================--


--- Pinch Gesture Recognizer Class.
-- gestures to recognize pinch motions
--
-- @type PinchGesture
--
local PinchGesture = newClass( Continuous, { name="Pinch Gesture" } )

--== Class Constants

PinchGesture.TYPE = Constants.TYPE_PINCH


--- Event name constant.
-- @field EVENT
-- @usage gesture:addEventListener( gesture.EVENT, handler )
-- @usage gesture:removeEventListener( gesture.EVENT, handler )

--- Event type constant, gesture recognized.
-- this type of event is sent out when a Gesture Recognizer has recognized the gesture
-- @field GESTURE
-- @usage
-- local function handler( event )
-- 	local gesture = event.target
-- 	if event.type == gesture.GESTURE then
-- 		-- we have our event !
-- 	end
-- end


--======================================================--
-- Start: Setup DMC Objects

function PinchGesture:__init__( params )
	-- print( "PinchGesture:__init__", params )
	params = params or {}
	if params.reset_scale==nil then params.reset_scale=Constants.PINCH_RESET_SCALE end
	if params.threshold==nil then params.threshold=Constants.PINCH_THRESHOLD end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._threshold = params.threshold
	self._reset_scale = params.reset_scale

	self._prev_scale = 1.0
	self._velocity = 0

	-- internal

	self._max_touches = 2
	self._min_touches = 2
	self._touch_dist = 0

end

function PinchGesture:__initComplete__()
	-- print( "PinchGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	--== use setters
	self.reset_scale = self._reset_scale
	self.threshold = self._threshold
end

--[[
function PinchGesture:__undoInitComplete__()
	-- print( "PinchGesture:__undoInitComplete__" )
	--==--
	self:superCall( '__undoInitComplete__' )
end
--]]

-- END: Setup DMC Objects
--======================================================--




--====================================================================--
--== Public Methods


--- Getters and Setters
-- @section getters-setters


--======================================================--
-- START: bogus methods, copied from super class

--- the gesture's id (string).
-- this is useful to differentiate between
-- different gestures attached to the same view object
--
-- @function .id
-- @usage print( gesture.id )
-- @usage gesture.id = "myid"
--
function PinchGesture.__gs_id() end

--- the gesture's target view (Display Object).
--
-- @function .view
-- @usage print( gesture.view )
-- @usage gesture.view = DisplayObject
--
function PinchGesture.__gs_view() end

--- the gesture's delegate (object/table)
--
-- @function .delegate
-- @usage print( gesture.delegate )
-- @usage gesture.delegate = DisplayObject
--
function PinchGesture.__gs_delegate() end

-- END: bogus methods, copied from super class
--======================================================--



--- whether to reset internal scale after pinch gesture is finished (boolean).
--
-- @function .reset_scale
-- @usage print( gesture.reset_scale )
-- @usage gesture.reset_scale = false
--
function PinchGesture.__getters:reset_scale()
	return self._reset_scale
end
function PinchGesture.__setters:reset_scale( value )
	assert( type(value)=='boolean' )
	--==--
	self._reset_scale = value
end


--- the minimum movement required to recognize a pinch gesture (number).
--
-- @function .threshold
-- @usage print( gesture.threshold )
-- @usage gesture.threshold = 5
--
function PinchGesture.__getters:threshold()
	return self._threshold
end
function PinchGesture.__setters:threshold( value )
	assert( type(value)=='number' and value>0 and value<256 )
	--==--
	self._threshold = value
end


-- @TODO
-- the velocity of the gesture motion (number).
-- Get Only
-- @function .velocity
-- @usage print( gesture.velocity )
--
function PinchGesture.__getters:velocity()
	return self._velocity
end



--====================================================================--
--== Private Methods


function PinchGesture:_do_reset()
	-- print( "PinchGesture:_do_reset" )
	Continuous._do_reset( self )
	self._velocity=0
	self._touch_dist = 0
	if self._reset_scale then
		self._prev_scale = 1.0
	end
end


function PinchGesture:_calculateTouchDistance( touches )
	-- print( "PinchGesture:_calculateTouchDistance" )
	local tch={}
	for _,v in pairs( touches ) do
		tinsert( tch, v )
	end
	local xDelta = tch[1].x-tch[2].x
	local yDelta = tch[1].y-tch[2].y
	return msqrt( xDelta*xDelta + yDelta*yDelta )
end

function PinchGesture:_calculateTouchChange( touches, o_dist )
	-- print( "PinchGesture:_calculateTouchChange", o_dist )
	local n_dist = self:_calculateTouchDistance( touches )
	return mabs( n_dist-o_dist )
end


-- experimental
function PinchGesture:_calculateAnchorPoint( x, y )
	local view = self.view
	local w, h = view.width, view.height
	local xP, yP = view:contentToLocal( x, y )
	-- print( xP, yP, w/2+xP, h/2+yP, (w/2+xP)/w, (h/2+yP)/h  )
	return (w/2+xP)/w, (h/2+yP)/h
end


function PinchGesture:_createMultitouchEvent( params )
	-- print( "PinchGesture:_createMultitouchEvent" )
	-- update to our "starting" touch
	params = params or {}
	--==--
	local me = Continuous._createMultitouchEvent( self, params )
	if params.phase==Continuous.BEGAN then
		self._touch_dist = self:_calculateTouchDistance( self._touches )
	end
	local o_dist = self._touch_dist
	local n_dist = o_dist
	me.scale = (1-(o_dist-n_dist)/o_dist)*self._prev_scale
	--[[
	experimental
	me.anchorX, me.anchorY = self:_calculateAnchorPoint( me.xStart, me.yStart )
	--]]
	return me
end

function PinchGesture:_updateMultitouchEvent( me, params )
	-- print( "PinchGesture:_updateMultitouchEvent" )
	me = Continuous._updateMultitouchEvent( self, me, params )

	local o_dist = self._touch_dist
	local n_dist = self:_calculateTouchDistance( self._touches )
	me.scale = (1-(o_dist-n_dist)/o_dist)*self._prev_scale
	return me
end

function PinchGesture:_endMultitouchEvent( me, params )
	-- print( "PinchGesture:_endMultitouchEvent" )
	me = Continuous._endMultitouchEvent( self, me, params )

	local o_dist = self._touch_dist
	local n_dist = self:_calculateTouchDistance( self._touches )
	me.scale = (1-(o_dist-n_dist)/o_dist)*self._prev_scale
	return me
end



--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function PinchGesture:touch( event )
	-- print("PinchGesture:touch", event.phase, event.id, self )
	Continuous.touch( self, event )

	local phase = event.phase
	local state = self:getState()
	local touch_count = self._touch_count

	local is_touch_ok = ( touch_count==2 )

	if phase=='began' then
		local touches = self._touches
		local t_max = self._max_touches

		self:_startFailTimer()
		self._gesture_attempt=true

		if is_touch_ok then
			self._touch_dist = self:_calculateTouchDistance( touches )
			self:_addMultitouchToQueue( Continuous.BEGAN )
			self:_startGestureTimer()
		elseif touch_count>t_max then
			self:gotoState( PinchGesture.STATE_FAILED )
		end

	elseif phase=='moved' then
		local touches = self._touches
		local threshold = self._threshold

		if state==Continuous.STATE_POSSIBLE then
			if is_touch_ok then
				self:_addMultitouchToQueue( Continuous.CHANGED )
				if self:_calculateTouchChange( touches, self._touch_dist )>threshold then
					self:gotoState( Continuous.STATE_BEGAN, event )
				end
			end
		elseif state==Continuous.STATE_BEGAN or state==Continuous.STATE_CHANGED then
			if is_touch_ok then
				self:gotoState( Continuous.STATE_CHANGED, event )
			else
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			end
		end

	elseif phase=='cancelled' then
		self:gotoState( PinchGesture.STATE_FAILED  )

	else -- ended
		if is_touch_ok then
			self:gotoState( Continuous.STATE_CHANGED, event )
		else
			if state==Continuous.STATE_BEGAN or state==Continuous.STATE_CHANGED then
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			else
				self:gotoState( Continuous.STATE_FAILED )
			end
		end

	end

end



--====================================================================--
--== State Machine


-- none




return PinchGesture

--====================================================================--
-- dmc_corona/dmc_gesture/pan_gesture.lua
--
-- Documentation:
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


--- Pan Gesture Module
-- @module PanGesture
-- @usage local Gesture = require 'dmc_gestures'
-- local view = display.newRect( 100, 100, 200, 200 )
-- local g = Gesture.newPanGesture( view )
-- g:addEventListener( g.EVENT, gHandler )


--====================================================================--
--== DMC Corona Library : Pan Gesture
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Pan Gesture
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local Continuous = require 'dmc_gestures.core.continuous_gesture'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass

local mabs = math.abs



--====================================================================--
--== Pan Gesture Class
--====================================================================--


--- Pan Gesture Recognizer Class.
-- gestures to recognize drag and pan motions
--
-- @type PanGesture
--
local PanGesture = newClass( Continuous, { name="Pan Gesture" } )

--== Class Constants

PanGesture.TYPE = 'pan'

PanGesture.MIN_DISTANCE_THRESHOLD = 10


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

function PanGesture:__init__( params )
	-- print( "PanGesture:__init__", params )
	params = params or {}
	if params.touches==nil then params.touches=1 end
	if params.max_touches==nil then params.max_touches=params.touches end
	if params.threshold==nil then params.threshold=PanGesture.MIN_DISTANCE_THRESHOLD end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._threshold = params.threshold

	self._max_touches = params.max_touches
	self._min_touches = params.touches
	self._max_time = 500

	self._velocity = 0
	self._touch_count = 0

	self._fail_timer = nil
	self._pan_timer = nil
end

function PanGesture:__initComplete__()
	-- print( "PanGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	--== use setters
	self.max_touches = self._max_touches
	self.min_touches = self._min_touches
	self.threshold = self._threshold
end

--[[
function PanGesture:__undoInitComplete__()
	-- print( "PanGesture:__undoInitComplete__" )
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
function PanGesture.__gs_id() end

--- the gesture's target view (Display Object).
--
-- @function .view
-- @usage print( gesture.view )
-- @usage gesture.view = DisplayObject
--
function PanGesture.__gs_view() end

--- the gesture's delegate (object/table)
--
-- @function .delegate
-- @usage print( gesture.delegate )
-- @usage gesture.delegate = DisplayObject
--
function PanGesture.__gs_delegate() end

-- END: bogus methods, copied from super class
--======================================================--



--- the velocity of the pan gesture motion (number).
-- Get Only
-- @function .velocity
-- @usage print( pan.velocity )
--
function PanGesture.__getters:velocity()
	return self._velocity
end


--- the distance a touch must move to count as the start of a pan (number).
--
-- @function .threshold
-- @usage print( gesture.threshold )
-- @usage gesture.threshold = 10
--
function PanGesture.__getters:threshold()
	return self._threshold
end
function PanGesture.__setters:threshold( value )
	assert( type(value)=='number' and value>0 and value<256 )
	--==--
	self._threshold = value
end


--- the minimum number of touches to recognize (number).
--
-- @function .touches
-- @usage print( gesture.touches )
-- @usage gesture.touches = 2
--
function PanGesture.__getters:touches()
	return self._min_touches
end
function PanGesture.__setters:touches( value )
	assert( type(value)=='number' and value>0 and value<256 )
	--==--
	self._min_touches = value
end


--- the maximum number of touches to recognize (number).
--
-- @function .max_touches
-- @usage print( gesture.max_touches )
-- @usage gesture.max_touches = 10
--
function PanGesture.__getters:max_touches()
	return self._max_touches
end
function PanGesture.__setters:max_touches( value )
	assert( type(value)=='number' and value>0 and value<256 )
	--==--
	self._max_touches = value
end




--====================================================================--
--== Private Methods


function PanGesture:_do_reset()
	-- print( "PanGesture:_do_reset" )
	Continuous._do_reset( self )
	self._velocity=0
	self._touch_count=0
end


-- create data structure for Gesture which has been recognized
-- code will put in began/changed/ended
function PanGesture:_createGestureEvent( event )
	return {
		x=event.x,
		y=event.y,
		xStart=event.xStart,
		yStart=event.yStart,
	}
end


function PanGesture:_stopFailTimer()
	-- print( "PanGesture:_stopFailTimer" )
	if not self._fail_timer then return end
	timer.cancel( self._fail_timer )
	self._fail_timer=nil
end

function PanGesture:_startFailTimer()
	-- print( "PanGesture:_startFailTimer", self )
	self:_stopFailTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( PanGesture.STATE_FAILED )
			self._fail_timer = nil
		end)
	end
	self._fail_timer = timer.performWithDelay( time, func )
end


function PanGesture:_stopPanTimer()
	-- print( "PanGesture:_stopPanTimer" )
	if not self._pan_timer then return end
	timer.cancel( self._pan_timer )
	self._pan_timer=nil
end

function PanGesture:_startPanTimer()
	-- print( "PanGesture:_startPanTimer", self )
	self:_stopFailTimer()
	self:_stopPanTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( PanGesture.STATE_FAILED )
			self._pan_timer = nil
		end)
	end
	self._pan_timer = timer.performWithDelay( time, func )
end


function PanGesture:_stopAllTimers()
	self:_stopFailTimer()
	self:_stopPanTimer()
end



--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function PanGesture:touch( event )
	-- print("PanGesture:touch", event.phase, event.id, self )
	Continuous.touch( self, event )

	local _mabs = mabs
	local phase = event.phase
	local threshold = self._threshold
	local state = self:getState()
	local t_max = self._max_touches
	local t_min = self._min_touches
	local touch_count = self._touch_count
	local data

	local is_touch_ok = ( touch_count>=t_min and touch_count<=t_max )

	if phase=='began' then
		self:_startFailTimer()
		if is_touch_ok then
			self:_startPanTimer()
		elseif touch_count>t_max then
			self:gotoState( PanGesture.STATE_FAILED )
		end

	elseif phase=='moved' then

		if state==Continuous.STATE_POSSIBLE then
			if is_touch_ok and (_mabs(event.xStart-event.x)>threshold or _mabs(event.yStart-event.y)>threshold) then
				self:gotoState( Continuous.STATE_BEGAN, event )
			end
		elseif state==Continuous.STATE_BEGAN then
			if is_touch_ok then
				self:gotoState( Continuous.STATE_CHANGED, event )
			else
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			end
		elseif state==Continuous.STATE_CHANGED then
			if is_touch_ok then
				self:gotoState( Continuous.STATE_CHANGED, event )
			else
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			end
		end

	elseif phase=='cancelled' then
		self:gotoState( PanGesture.STATE_FAILED  )

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


--== State Recognized ==--

function PanGesture:do_state_began( params )
	-- print( "PanGesture:do_state_began" )
	self:_stopAllTimers()
	Continuous.do_state_began( self, params )
end


--== State Failed ==--

function PanGesture:do_state_failed( params )
	-- print( "PanGesture:do_state_failed" )
	self:_stopAllTimers()
	Continuous.do_state_failed( self, params )
end





return PanGesture

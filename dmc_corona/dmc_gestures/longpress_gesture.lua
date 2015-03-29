--====================================================================--
-- dmc_corona/dmc_gesture/longpress_gesture.lua
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


--- Long Press Gesture Module
-- @module LongPressGesture
-- @usage local Gesture = require 'dmc_gestures'
-- local view = display.newRect( 100, 100, 200, 200 )
-- local g = Gesture.newLongPressGesture( view )
-- g:addEventListener( g.EVENT, gHandler )



--====================================================================--
--== DMC Corona Library : Long Press Gesture
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Long Press Gesture
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
local tcancel = timer.cancel
local tdelay = timer.performWithDelay



--====================================================================--
--== Long Press Gesture Class
--====================================================================--


--- Tap Gesture Recognizer Class.
-- gestures to recognize tap motions
--
-- @type LongPressGesture
--
local LongPressGesture = newClass( Continuous, { name="Long Press Gesture" } )

--== Class Constants

LongPressGesture.TYPE = Constants.TYPE_LONGPRESS


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

function LongPressGesture:__init__( params )
	-- print( "LongPressGesture:__init__", params )
	params = params or {}
	if params.accuracy==nil then params.accuracy=Constants.LONGPRESS_ACCURACY end
	if params.duration==nil then params.duration=Constants.LONGPRESS_DURATION end
	if params.taps==nil then params.taps=Constants.LONGPRESS_TAPS end
	if params.touches==nil then params.touches=Constants.LONGPRESS_TOUCHES end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._min_accuracy = params.accuracy
	self._min_duration = params.duration
	self._req_taps = params.taps
	self._req_touches = params.touches

	self._tap_count = 0 -- how many taps

	self._press_timer=nil

end


function LongPressGesture:__initComplete__()
	-- print( "LongPressGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	--== use setters
	self.accuracy = self._min_accuracy
	self.duration = self._min_duration
	self.taps = self._req_taps
	self.touches = self._req_touches
end

--[[
function LongPressGesture:__undoInitComplete__()
	-- print( "LongPressGesture:__undoInitComplete__" )
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

--- the id (string).
-- this is useful to differentiate between
-- different gestures attached to the same view object
--
-- @function .id
-- @usage print( gesture.id )
-- @usage gesture.id = "myid"
--
function LongPressGesture.__gs_id() end

--- the target view (Display Object).
--
-- @function .view
-- @usage print( gesture.view )
-- @usage gesture.view = DisplayObject
--
function LongPressGesture.__gs_view() end

--- a gesture delegate (object/table)
--
-- @function .delegate
-- @usage print( gesture.delegate )
-- @usage gesture.delegate = DisplayObject
--
function LongPressGesture.__gs_delegate() end

-- END: bogus methods, copied from super class
--======================================================--



--- the maximum finger-movement allowed (number).
-- the limit of movement for a gesture to be recognized, radius in pixels.
-- value must be greater than zero. default is 10.
--
-- @function .accuracy
-- @usage print( gesture.accuracy )
-- @usage gesture.accuracy = 10
--
function LongPressGesture.__getters:accuracy()
	return self._min_accuracy
end
function LongPressGesture.__setters:accuracy( value )
	assert( type(value)=='number' and value>0 )
	--==--
	self._min_accuracy = value
end


--- the minimum time required for recognition (number).
-- this is the minimum period that a press must be held for the gesture to be recognized. time is in milliseconds. default is 500ms.
--
-- @function .duration
-- @usage print( gesture.duration )
-- @usage gesture.duration = 400
--
function LongPressGesture.__getters:duration()
	return self._min_duration
end
function LongPressGesture.__setters:duration( value )
	assert( type(value)=='number' and value>50 )
	--==--
	self._min_duration = value
end


--- the minimum number of taps for recognition (number).
-- this specifies the minimum number of taps required to succeed. the long-press is _after_ the number of taps. default is zero (0).
-- value >= 0
--
-- @function .taps
-- @usage print( gesture.taps )
-- @usage gesture.taps = 2
--
function LongPressGesture.__getters:taps()
	return self._req_taps
end
function LongPressGesture.__setters:taps( value )
	assert( type(value)=='number' and value>=0 )
	--==--
	self._req_taps = value
end


--- the minimum number of touches for recognition (number).
-- this is used to specify the number of fingers required for each tap, eg a two-fingered single-tap, three-fingered double-tap.
-- greater than 0, less than 6
--
-- @function .touches
-- @usage print( gesture.touches )
-- @usage gesture.touches = 2
--
function LongPressGesture.__getters:touches()
	return self._req_touches
end
function LongPressGesture.__setters:touches( value )
	assert( type(value)=='number' and ( value>0 and value<6 ) )
	--==--
	self._req_touches = value
end



--====================================================================--
--== Private Methods


function LongPressGesture:_do_reset()
	Continuous._do_reset( self )
	self._tap_count = 0
end


function LongPressGesture:_stopPressTimer()
	-- print( "LongPressGesture:_stopPressTimer" )
	if not self._press_timer then return end
	tcancel( self._press_timer )
	self._press_timer=nil
end

function LongPressGesture:_startPressTimer()
	-- print( "LongPressGesture:_startPressTimer", self )
	local time=self._min_duration

	self:_stopAllTimers()
	local func = function()
		tdelay( 1, function()
			self:gotoState( Continuous.STATE_BEGAN )
			self._press_timer=nil
		end)
	end
	self._press_timer = tdelay( time, func )
end


function LongPressGesture:_stopAllTimers()
	Continuous._stopAllTimers( self )
	self:_stopPressTimer()
end



--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function LongPressGesture:touch( event )
	-- print("LongPressGesture:touch", event.phase, self )
	Continuous.touch( self, event )

	local phase = event.phase
	local state = self:getState()

	local touch_count = self._touch_count
	local r_touches = self._req_touches

	local is_touch_ok = ( touch_count==r_touches )

	if phase=='began' then
		local r_taps = self._req_taps
		local taps = self._tap_count

		self:_startFailTimer()
		self._gesture_attempt=true

		if is_touch_ok and taps==r_taps then
			self:_addMultitouchToQueue( Continuous.BEGAN )
			self:_startPressTimer()

		elseif is_touch_ok then
			self:_startGestureTimer()

		elseif touch_count>r_touches then
			self:gotoState( Continuous.STATE_FAILED )
		end

	elseif phase=='moved' then
		local _mabs = mabs
		local accuracy = self._min_accuracy

		if state==Continuous.STATE_POSSIBLE then
			if _mabs(event.xStart-event.x)>accuracy or _mabs(event.yStart-event.y)>accuracy then
				self:gotoState( Continuous.STATE_FAILED )
			end

		elseif state==Continuous.STATE_BEGAN or state==Continuous.STATE_CHANGED then
			if is_touch_ok then
				self:gotoState( Continuous.STATE_CHANGED, event )
			else
				self:gotoState( Continuous.STATE_RECOGNIZED, event )
			end

		end

	elseif phase=='cancelled' then
		self:gotoState( Continuous.STATE_FAILED )

	else -- ended

		if state==Continuous.STATE_POSSIBLE then
			local r_taps = self._req_taps
			local taps = self._tap_count

			if self._press_timer then
				self:_stopPressTimer()
				self:gotoState( Continuous.STATE_FAILED )
			end

			if self._gesture_timer and touch_count==0 then
				taps = taps + 1
				self:_stopGestureTimer()
			end
			if self._gesture_attempt then
				-- remove these touch events so they
				-- are not used in Centroid calculation
				self:_removeTouchEvent( event )
			end

			if taps>r_taps then
				self:gotoState( Continuous.STATE_FAILED )
			else
				self:_startFailTimer()
			end

			self._tap_count = taps

		elseif state==Continuous.STATE_BEGAN or state==Continuous.STATE_CHANGED then
			self:gotoState( Continuous.STATE_RECOGNIZED, event )

		end

	end

end



--====================================================================--
--== State Machine


-- none




return LongPressGesture


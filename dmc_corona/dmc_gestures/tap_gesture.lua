--====================================================================--
-- dmc_corona/dmc_gesture/tap_gesture.lua
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


--- Tap Gesture Module
-- @module TapGesture
-- @usage local Gesture = require 'dmc_gestures'
-- local view = display.newRect( 100, 100, 200, 200 )
-- local g = Gesture.newTapGesture( view )
-- g:addEventListener( g.EVENT, gHandler )


--====================================================================--
--== DMC Corona Library : Tap Gesture
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Tap Gesture
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local Gesture = require 'dmc_gestures.core.gesture'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass

local mabs = math.abs



--====================================================================--
--== Tap Gesture Class
--====================================================================--


--- Tap Gesture Recognizer Class.
-- gestures to recognize tap motions
--
-- @type TapGesture
--
local TapGesture = newClass( Gesture, { name="Tap Gesture" } )

--== Class Constants

TapGesture.TYPE = 'tap'

TapGesture.MAX_TAP_THRESHOLD = 300
TapGesture.MIN_ACCURACY = 10


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

function TapGesture:__init__( params )
	-- print( "TapGesture:__init__", params )
	params = params or {}
	if params.accuracy==nil then params.accuracy=TapGesture.MIN_ACCURACY end
	if params.taps==nil then params.taps=1 end
	if params.time==nil then params.time=TapGesture.MAX_TAP_THRESHOLD end
	if params.touches==nil then params.touches=1 end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._min_accuracy = params.accuracy
	self._req_taps = params.taps
	self._max_time = params.time
	self._req_touches = params.touches

	self._tap_count = 0 -- how many we've seen
	self._tap_timer = nil

	self._fail_timer = nil

end


function TapGesture:__initComplete__()
	-- print( "TapGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	--== use setters
	self.accuracy = self._min_accuracy
	self.taps = self._req_taps
	self.time = self._max_time
	self.touches = self._req_touches
end

--[[
function TapGesture:__undoInitComplete__()
	-- print( "TapGesture:__undoInitComplete__" )
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
function TapGesture.__gs_id() end

--- the target view (Display Object).
--
-- @function .view
-- @usage print( gesture.view )
-- @usage gesture.view = DisplayObject
--
function TapGesture.__gs_view() end

--- a gesture delegate (object/table)
--
-- @function .delegate
-- @usage print( gesture.delegate )
-- @usage gesture.delegate = DisplayObject
--
function TapGesture.__gs_delegate() end

-- END: bogus methods, copied from super class
--======================================================--



--- the maximum movement allowed between taps, radius (number).
--
-- @function .accuracy
-- @usage print( gesture.accuracy )
-- @usage gesture.accuracy = 10
--
function TapGesture.__getters:accuracy()
	return self._min_accuracy
end
function TapGesture.__setters:accuracy( value )
	assert( type(value)=='number' and value>0 )
	--==--
	self._min_accuracy = value
end


--- the minimum number of taps required to recognize (number).
-- this specifies the minimum number of taps required to succeed.
--
-- @function .taps
-- @usage print( gesture.taps )
-- @usage gesture.taps = 2
--
function TapGesture.__getters:taps()
	return self._req_taps
end
function TapGesture.__setters:taps( value )
	assert( type(value)=='number' and ( value>0 and value<6 ) )
	--==--
	self._req_taps = value
end


--- the maximum time between tap touches in milliseconds (number).
-- this time is more important when doing multiple-tap sequences, eg double-tap. if any tap occurs after this time has elapsed, then the gesture fails. note: the timer is reset upon each valid tap.
--
-- @function .time
-- @usage print( gesture.time )
-- @usage gesture.time = 400
--
function TapGesture.__getters:time()
	return self._max_time
end
function TapGesture.__setters:time( value )
	assert( type(value)=='number' and value>150 )
	--==--
	self._max_time = value
end


--- the minimum number of touches required to recognize (number).
-- this is used to specify the number of fingers required for each tap, eg a two-fingered single-tap, three-fingered double-tap.
--
-- @function .touches
-- @usage print( gesture.touches )
-- @usage gesture.touches = 2
--
function TapGesture.__getters:touches()
	return self._req_touches
end
function TapGesture.__setters:touches( value )
	assert( type(value)=='number' and ( value>0 and value<5 ) )
	--==--
	self._req_touches = value
end



--====================================================================--
--== Private Methods


function TapGesture:_do_reset()
	-- print( "TapGesture:_do_reset" )
	Gesture._do_reset( self )
	self._tap_count=0
	self:_stopAllTimers()
end


function TapGesture:_stopFailTimer()
	-- print( "TapGesture:_stopFailTimer" )
	if not self._fail_timer then return end
	timer.cancel( self._fail_timer )
	self._fail_timer=nil
end

function TapGesture:_startFailTimer()
	-- print( "TapGesture:_startFailTimer", self )
	self:_stopFailTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( TapGesture.STATE_FAILED )
			self._fail_timer = nil
		end)
	end
	self._fail_timer = timer.performWithDelay( time, func )
end



function TapGesture:_stopTapTimer()
	-- print( "TapGesture:_stopTapTimer" )
	if not self._tap_timer then return end
	timer.cancel( self._tap_timer )
	self._tap_timer=nil
end

function TapGesture:_startTapTimer()
	-- print( "TapGesture:_startTapTimer", self )
	self:_stopFailTimer()
	self:_stopTapTimer()
	local time = self._max_time
	local func = function()
		timer.performWithDelay( 1, function()
			self:gotoState( TapGesture.STATE_FAILED )
			self._tap_timer = nil
		end)
	end
	self._tap_timer = timer.performWithDelay( time, func )
end


function TapGesture:_stopAllTimers()
	self:_stopFailTimer()
	self:_stopTapTimer()
end



--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function TapGesture:touch( event )
	-- print("TapGesture:touch", event.phase, self )
	Gesture.touch( self, event )

	local phase = event.phase
	local touch_count = self._touch_count

	if phase=='began' then
		self:_startFailTimer()
		local r_touches = self._req_touches
		if touch_count==r_touches then
			self:_startTapTimer()
		elseif touch_count>r_touches then
			self:gotoState( TapGesture.STATE_FAILED )
		end

	elseif phase=='moved' then
		local _mabs = mabs
		local accuracy = self._min_accuracy
		if _mabs(event.xStart-event.x)>accuracy or _mabs(event.yStart-event.y)>accuracy then
			self:gotoState( TapGesture.STATE_FAILED )
		end

	elseif phase=='cancelled' then
		self:gotoState( TapGesture.STATE_FAILED )

	else -- ended
		local r_taps = self._req_taps
		local taps = self._tap_count
		if self._tap_timer and touch_count==0 then
			taps = taps + 1
			self:_stopTapTimer()
		end
		if taps==r_taps then
			self:gotoState( TapGesture.STATE_RECOGNIZED )
		elseif taps>r_taps then
			self:gotoState( TapGesture.STATE_FAILED )
		else
			self:_startFailTimer()
		end
		self._tap_count = taps
	end

end



--====================================================================--
--== State Machine


--== State Recognized ==--

function TapGesture:do_state_recognized( params )
	-- print( "TapGesture:do_state_recognized" )
	self:_stopAllTimers()
	Gesture.do_state_recognized( self, params )
end


--== State Failed ==--

function TapGesture:do_state_failed( params )
	-- print( "TapGesture:do_state_failed" )
	self:_stopAllTimers()
	Gesture.do_state_failed( self, params )
end




return TapGesture


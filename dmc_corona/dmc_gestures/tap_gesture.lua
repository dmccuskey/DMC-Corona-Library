--====================================================================--
-- dmc_corona/dmc_gesture/tap_gesture.lua
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
local Constants = require 'dmc_gestures.gesture_constants'



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
-- **Inherits from:**
--
-- * @{Gesture.Gesture}
--
-- @classmod Gesture.Tap
--
-- @usage local Gesture = require 'dmc_gestures'
-- local view = display.newRect( 100, 100, 200, 200 )
-- local g = Gesture.newTapGesture( view )
-- g:addEventListener( g.EVENT, gHandler )

local TapGesture = newClass( Gesture, { name="Tap Gesture" } )

--- Class Constants.
-- @section

--== Class Constants

TapGesture.TYPE = Constants.TYPE_TAP


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
	if params.accuracy==nil then params.accuracy=Constants.TAP_ACCURACY end
	if params.taps==nil then params.taps=Constants.TAP_TAPS end
	if params.touches==nil then params.touches=Constants.TAP_TOUCHES end

	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._min_accuracy = params.accuracy
	self._req_taps = params.taps
	self._req_touches = params.touches

	self._tap_count = 0 -- how many taps

end


function TapGesture:__initComplete__()
	-- print( "TapGesture:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	--== use setters
	self.accuracy = self._min_accuracy
	self.taps = self._req_taps
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


--======================================================--
-- Getters/Setters

--- Getters and Setters
-- @section getters-setters


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
end



--====================================================================--
--== Event Handlers


-- event is Corona Touch Event
--
function TapGesture:touch( event )
	-- print("TapGesture:touch", event.phase, self )
	Gesture.touch( self, event )

	local phase = event.phase

	if phase=='began' then
		local r_touches = self._req_touches
		local touch_count = self._touch_count

		self:_startFailTimer()
		self._gesture_attempt=true

		if touch_count==r_touches then
			self:_startGestureTimer()
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
		local touch_count = self._touch_count
		local r_taps = self._req_taps
		local taps = self._tap_count

		if self._gesture_timer and touch_count==0 then
			taps = taps + 1
			self:_stopGestureTimer()
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


-- none




return TapGesture


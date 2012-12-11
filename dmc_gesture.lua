--===================================================================--
-- dmc_gesture.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_gesture.lua
--===================================================================--

--[[

Copyright (C) 2012 David McCuskey. All Rights Reserved.

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

local VERSION = "0.3.1"


--===================================================================--
-- Imports
--===================================================================--

local TouchMgr = require( "dmc_touchmanager" )

--===================================================================--
-- Setup, Constants
--===================================================================--

local SWIPE_EVENT = "swipe_event"


--===================================================================--
-- Support Functions
--===================================================================--



function checkBounds( value, bounds )

	local v = value
	if bounds[1] ~= nil and v < bounds[1] then
		v = bounds[1]

	elseif bounds[2] ~= nil and v > bounds[2] then
		v = bounds[2]
	end

	return v
end


function angle_given_x_y( x, y )

	return math.deg( math.atan2( y, x ) )

end

function vector_given_x_y( x, y )

	return math.floor( math.sqrt( math.pow( x, 2 ) + math.pow( y, 2 ) ) )

end

function direction_given_angle( angle, limit )
	--print( "direction_given_angle" .. angle .. ":" .. limit )

	local angle_abs = math.abs( angle )
	local angle_sign = ( angle < 0 ) and -1 or 1
	local dir

	-- 0 degrees
	if angle_abs >= 0 and angle_abs < (0 + limit) then
		dir = "right"

	-- 90 degrees, negative
	elseif angle_sign == -1 and angle_abs > (90-limit) and angle_abs < (90+limit) then
		dir = "up"

	-- 90 degrees, positive
	elseif angle_sign == 1 and angle_abs > (90-limit) and angle_abs < (90+limit) then
		dir = "down"

	-- 180 degrees
	elseif angle_abs > (180-limit) and angle_abs <= 180 then
		dir = "left"

	-- default
	else
		dir = nil
	end

	return dir

end

function swipeTouchHandler( event )
	--print( "swipeTouchHandler", event )

	local obj = event.target
	local dmc = obj.__dmc.gesture
	local et, xDelta, yDelta, vector, angle

	-- create our event to dispatch
	local e = {
		name = SWIPE_EVENT,
		phase = event.phase,

		target = obj,
		direction = nil,
		touch = {}
	}


	--== Start processing the Corona touch event ==--

	if event.phase == 'began' then

		TouchMgr:setFocus( event.target, event.id )

		-- fill in event and dispatch
		et = e.touch
		et.xStart = event.xStart
		et.yStart = event.yStart
		et.x = event.x
		et.y = event.y

		if obj.dispatchEvent ~= nil then
			obj:dispatchEvent( e )
		end

		return true

	elseif event.phase == 'moved' then

		if event.isFocused then

			xDelta = event.x - event.xStart
			yDelta = event.y - event.yStart

			vector = vector_given_x_y( xDelta, yDelta )
			angle = angle_given_x_y( xDelta, yDelta )
			e.swipe = {
				angle = angle,
				length = vector
			}

			-- fill in rest of event and dispatch
			et = e.touch
			et.xStart = event.xStart
			et.yStart = event.yStart
			et.x = event.x
			et.y = event.y

			if obj.dispatchEvent ~= nil then
				obj:dispatchEvent( e )
			end

			return true

		end

	elseif ( event.phase == 'ended' or event.phase == 'canceled' ) then

		if event.isFocused then

			TouchMgr:unsetFocus( event.target, event.id )

			if dmc ~= nil and dmc.useStrictBounds and obj ~= nil then
				local bounds = obj.contentBounds
				xDelta = checkBounds( event.x, { bounds.xMin, bounds.xMax } ) - event.xStart
				yDelta = checkBounds( event.y, { bounds.yMin, bounds.yMax } ) - event.yStart
			else
				xDelta = event.x - event.xStart
				yDelta = event.y - event.yStart
			end

			vector = vector_given_x_y( xDelta, yDelta )
			angle = angle_given_x_y( xDelta, yDelta )
			e.swipe = {
				angle = angle,
				length = vector
			}

			if vector >= dmc.swipeLength then
				e.direction = direction_given_angle( angle, dmc.limitAngle )
			end

			-- fill in rest of event and dispatch
			et = e.touch
			et.xStart = event.xStart
			et.yStart = event.yStart
			et.x = event.x
			et.y = event.y


			if obj.dispatchEvent ~= nil then
				obj:dispatchEvent( e )
			end

			return true

		end

	end

end





--===================================================================--
-- Gesture Object
--===================================================================--


local Gesture = {}


--== Constants ==--

local MAX_LIMIT_ANGLE = 45
local MIN_SWIPE_LENGTH = 10

Gesture.DEFAULT_LIMIT_ANGLE = 20
Gesture.DEFAULT_SWIPE_LENGTH = 150

Gesture.SWIPE_EVENT = SWIPE_EVENT


--== Functions ==--


-- swipe()
--
-- blesses an object to have swipe properties
--
-- @param obj a Corona-type object
-- @param params a Lua table with modifiers
-- @return the object which has been blessed (original), or nil on error
--
Gesture.activate = function( obj, params )

	params = params or {}

	-- sanity check
	if obj.__dmc and obj.__dmc.gesture then
		print( "WARNING: only initialize Gesture once !" )
		return nil
	end

	-- create our fancy callback and set event listener
	TouchMgr:register( obj, swipeTouchHandler )


	--== Setup special dmc_gesture variables ==--

	if obj.__dmc == nil then obj.__dmc = {} end

	local dmc = {

		-- these will be initialized below
		limitAngle = nil,
		swipeLength = nil,
		useStrictBounds = nil
	}

	-- process the limit angle
	if params.limitAngle == nil then
		dmc.limitAngle = Gesture.DEFAULT_LIMIT_ANGLE
	elseif math.abs( params.limitAngle ) > MAX_LIMIT_ANGLE then
		dmc.limitAngle = MAX_LIMIT_ANGLE
	else 
		dmc.limitAngle = math.abs( params.limitAngle )
	end

	-- process the swipe length 
	if params.swipeLength == nil or params.swipeLength < MIN_SWIPE_LENGTH then
		dmc.swipeLength = Gesture.DEFAULT_SWIPE_LENGTH
	else
		dmc.swipeLength = params.swipeLength
	end

	-- process use of strict bounds
	if params.useStrictBounds == nil then
		dmc.useStrictBounds = false
	else
		dmc.useStrictBounds = params.useStrictBounds
	end

	obj.__dmc.gesture = dmc

	return obj

end

Gesture.deactivate = function( obj )
	local dmc = obj.__dmc.gesture
	obj.__dmc.gesture = nil

	TouchMgr:unregister( obj, swipeTouchHandler )

end


return Gesture

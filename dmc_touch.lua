--===================================================================--
-- dmc_touch.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_touch.lua
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

local VERSION = "0.1.0"


--===================================================================--
-- Imports
--===================================================================--

--===================================================================--
-- Setup, Constants
--===================================================================--

local MOVE_EVENT = "move_event"


--===================================================================--
-- Support Functions
--===================================================================--


-- createObjectCallback()
-- copied from dmc_utils
--
function createObjectCallback( object, method )
	return function( ... )
		method( object, ... )
	end
end


function finishPhaseBegan( obj )

	local dmc = obj.__dmc.touch
	local f = dmc.handler

	dmc.isMoving = true

	obj:removeEventListener( "touch", f )
	Runtime:addEventListener( "touch", f )

end

function finishPhaseEnd( obj )

	local dmc = obj.__dmc.touch
	local f = dmc.handler

	dmc.isMoving = false

	Runtime:removeEventListener( "touch", f )
	obj:addEventListener( "touch", f )

end


-- angle in degrees
function y_given_x_angle( x, angle )
	--print( "y_given_x_angle" )

	-- use negative angle to compensate for difference
	-- in trig angles and Corona angles
	return x * math.tan( math.rad( - angle ) )

end

-- angle in degrees
function x_given_y_angle( y, angle )
	--print( "y_given_x_angle" )

	-- use negative angle to compensate for difference
	-- in trig angles and Corona angles
	return y / math.tan( math.rad( - angle ) )
end


function checkBounds( value, bounds )

	local v = value
	if bounds[1] ~= nil and v < bounds[1] then
		v = bounds[1]

	elseif bounds[2] ~= nil and v > bounds[2] then
		v = bounds[2]
	end

	return v
end

function touchHandler( obj, event )

	local f, xPos, yPos
	local dmc = obj.__dmc.touch

	-- create our event to dispatch
	local e = {
		name = MOVE_EVENT,
		phase = event.phase,

		target = obj, 
		moveX = nil,
		moveY = nil,
	}


	--== Start processing the Corona touch event ==--

	if event.phase == 'began' then

		dmc.offsetX = obj.x - event.x
		dmc.offsetY = obj.y - event.y

		-- fill in event and dispatch
		e.moveX = obj.x
		e.moveY = obj.y
		obj:dispatchEvent( e )

		-- using hack as described here:
		-- http://developer.anscamobile.com/reference/index/objectaddeventlistener
		--
		f = createObjectCallback( obj, finishPhaseBegan )
		timer.performWithDelay( 1, f )


	elseif event.phase == 'moved' and dmc.isMoving == true then

		local SIN_45DEG = 0.707

		local xB = dmc.xBounds
		local yB = dmc.yBounds
		local cA = dmc.constrainAngle

		local xDelta, yDelta, sin_cA

		if cA then
			sin_cA = math.sin( math.rad( cA ) )
		end


		-- calculate position based on touch
		xPos = event.x + dmc.offsetX
		yPos = event.y + dmc.offsetY


		-- re-set position based on parameters

		if cA and xB then

		 	xPos = checkBounds( xPos, dmc.xBounds )
			xDelta = xPos - dmc.initialX 
			yDelta = y_given_x_angle( xDelta, cA )
			yPos = yDelta + dmc.initialY

		elseif cA and yB then

		 	yPos = checkBounds( yPos, dmc.yBounds )
			yDelta = yPos - dmc.initialY
			xDelta = x_given_y_angle( yDelta, cA )
			xPos = xDelta + dmc.initialX

		elseif cA and math.sin( cA ) <= SIN_45DEG then

			xDelta = xPos - dmc.initialX 
			yDelta = y_given_x_angle( xDelta, cA )
			yPos = yDelta + dmc.initialY

		elseif cA and math.abs( cA ) > SIN_45DEG then

			yDelta = yPos - dmc.initialY
			xDelta = x_given_y_angle( yDelta, cA )
			xPos = xDelta + dmc.initialX

		elseif xB and yB then

		 	xPos = checkBounds( xPos, dmc.xBounds )
		 	yPos = checkBounds( yPos, dmc.yBounds )

		elseif xB then

		 	xPos = checkBounds( xPos, dmc.xBounds )

		elseif yB then

		 	yPos = checkBounds( yPos, dmc.yBounds )

		elseif not xB and not yB and not cA then

			-- pass here, we've already done calculations

		else
			print( "ERROR: you can't do that" )
		end

		-- set the new position
		obj.x = xPos ; obj.y = yPos

		-- fill in event and dispatch
		e.moveX = obj.x
		e.moveY = obj.y
		obj:dispatchEvent( e )


	elseif ( event.phase == 'ended' or event.phase == 'canceled' ) and dmc.isMoving == true then 

		-- fill in event and dispatch
		e.moveX = obj.x
		e.moveY = obj.y
		obj:dispatchEvent( e )


		-- using hack as described here:
		-- http://developer.anscamobile.com/reference/index/objectaddeventlistener
		--
		f = createObjectCallback( obj, finishPhaseEnd )
		timer.performWithDelay( 1, f )

	end

end



--===================================================================--
-- Touch Object
--===================================================================--

local Touch = {}

Touch.MOVE_EVENT = MOVE_EVENT

Touch.move = function( obj, params )

	params = params or {}

	-- sanity check
	if obj.__dmc and obj.__dmc.touch then
		print( "WARNING: only initialize move() once !" )
		return nil
	end

	-- create our fancy callback and set event listener
	local f = createObjectCallback( obj, touchHandler )
	obj:addEventListener( "touch", f )

	-- store special dmc_touch variables
	if obj.__dmc == nil then obj.__dmc = {} end

	local dmc = {
		initialX = obj.x,
		initialY = obj.y,
		offsetX = 0,
		offsetY = 0,
		handler = f
	}
	dmc.xBounds = params.xBounds
	dmc.yBounds = params.yBounds
	dmc.constrainAngle = params.constrainAngle

	obj.__dmc.touch = dmc

	return obj

end


return Touch

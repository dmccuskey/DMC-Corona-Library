--===================================================================--
-- dmc_multitouch.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_multitouch.lua
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

local VERSION = "0.2.0"
local RAD_TO_DEG = 180 / math.pi


--===================================================================--
-- Imports
--===================================================================--

--===================================================================--
-- Setup, Constants
--===================================================================--

local MULTITOUCH_EVENT = "multitouch_event"

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



local obj
local debugObjs = {}

-- blue spot over center of main object
obj = display.newRect( 0, 0, 30, 30 )
obj:setFillColor(0,0,255)
obj:toFront()
debugObjs["objCenter"] = obj

-- green spot over midpoint center
obj = display.newRect( 0, 0, 16, 16 )
obj:setFillColor(0,255,0)
obj:toFront()
debugObjs["touchCenter"] = obj

-- red spot over calculated center
obj = display.newRect( 0, 0, 16, 16 )
obj:setFillColor(255,0,0)
obj:toFront()
debugObjs["calcCenter"] = obj



local function calculateBase( obj )
	print( "======== calculateBase" )
	local dmc = obj.__dmc.multitouch
	local touches = dmc.touches
	local touchStack = dmc.touchStack

	local cO -- corona obj

	local dx, dy
	local x, y

	touch = touches[ touchStack[1] ]
	event = touches[ touchStack[2] ]

	if not touch or not event then
		dmc.distanceTouch = nil
		return nil
	end


	dx = touch.x - event.x
	dy = -( touch.y - event.y )

	-- save midpoint between touches
	dmc.midpointTouch = { x=touch.x-dx/2, y=touch.y+dy/2 }

	--print( dx, dy )

	-- update touch center point
	cO = debugObjs["touchCenter"]
 	cO.x = dmc.midpointTouch.x ; cO.y = dmc.midpointTouch.y
	print( dmc.midpointTouch.x, dmc.midpointTouch.y )


	-- save current properties
	dmc.scaleOrig = obj.xScale
	dmc.angleOrig = -obj.rotation -- convert from Corona to trig angles

	-- save distance, angle between touches
	dmc.distanceTouch = math.sqrt( dx*dx + dy*dy )
	dmc.angleTouch = math.deg( math.atan2( dy, dx ) )
	--print( dx, dy )
	print( 'distance ', dx, dy, dmc.distanceTouch )
	print( "angle ", dmc.angleOrig, dmc.angleTouch )


	-- center point calculations
	dx = obj.x - dmc.midpointTouch.x
	dy = -( obj.y - dmc.midpointTouch.y )

	--print( display.contentWidth, display.contentHeight )
	--print( dmc.midpointTouch.x, obj.x )
	dmc.distanceCenter = math.sqrt( dx*dx + dy*dy )
	dmc.angleCenter = math.deg( math.atan2( dy, dx ) )
	print( "dco: ", dmc.distanceCenter )
	print( "aco: ", dmc.angleCenter ) -- trig angle
	print( "obj: ", dmc.scaleOrig, obj.x, obj.y )


	x = math.cos( math.rad( dmc.angleCenter ) ) * dmc.distanceCenter + dmc.midpointTouch.x
	y = math.sin( math.rad( -dmc.angleCenter ) ) * dmc.distanceCenter + dmc.midpointTouch.y

	print( "objx.y: ", obj.x, obj.y )
	print( "x.y: ", x, y )

	cO = debugObjs["calcCenter"]
	cO.x = x ; cO.y = y


	--return dx, dy
end


local function calculateDelta( obj )
	local dmc = obj.__dmc.multitouch
	print( "<<<<<<<<<< calculateDelta" )
	local touches = dmc.touches
	local touchStack = dmc.touchStack

	local cO -- corona obj
	local dx, dy
	local x, y


	touch = touches[ touchStack[1] ]
	event = touches[ touchStack[2] ]

	if not touch or not event then
		dmc.distanceTouch = nil
		return nil
	end


	dx = touch.x - event.x
	dy = -( touch.y - event.y )

	-- calculate new midpoint
	dmc.midpointTouch = { x=touch.x-dx/2, y=touch.y+dy/2 }

	-- update touch center point
	cO = debugObjs["touchCenter"]
 	cO.x = dmc.midpointTouch.x ; cO.y = dmc.midpointTouch.y
	print( dmc.midpointTouch.x, dmc.midpointTouch.y )


	-- calculate new distance and scale
	local d, scale, scaled
	if not dmc.doPinch then
		scale = 1.0
		scaled = dmc.scaleOrig
	else
		d = math.sqrt( dx*dx + dy*dy )
		scale = d / dmc.distanceTouch
		scaled = scale * dmc.scaleOrig
		print( 'distance ', scale, dx, dy, dmc.distanceTouch, d )
	end


	-- calculate new angle
	local newAngle = math.deg( math.atan2( dy, dx ) )
	local angleDiff = newAngle - dmc.angleTouch -- negative is clockwise
	local rotation = -( dmc.angleOrig + angleDiff )

	--print( "Angles ", dmc.angleOrig, dmc.angleTouch, newAngle )


	--local d2 = dmc.distanceCenter * scale
	--print( "dco2: ", dmc.scaleOrig, scale, d2 )



	x = dmc.midpointTouch.x + math.cos( math.rad( -( dmc.angleCenter + angleDiff ) ) ) * ( dmc.distanceCenter * scale )
	y = dmc.midpointTouch.y + math.sin( math.rad( -( dmc.angleCenter + angleDiff ) ) ) * ( dmc.distanceCenter * scale )
	print( "x.y: ", x, y )

--[[
	print( dmc.angleCenter )
	print( math.rad( - dmc.angleCenter ) )
	print( math.rad( dmc.angleCenter ) )

	print( math.asin( math.rad( dmc.angleCenter ) ) )
	print( math.asin( math.rad( - dmc.angleCenter ) ) )
	--print( math.asin( 4/4 ) )
	--print( math.deg( math.asin( 4/4 ) ) )
	print( "dco2: ", d2 )
--]]
	cO = debugObjs["calcCenter"]
	cO.x = x
	cO.y = y


	-- pack up results
	local ret = {
		scale = scaled,
		rotation = rotation,
		x = x,
		y = y
	}

	return ret

end



function multitouchTouchHandler( obj, event )
	--print( "multitouchTouchHandler", event.id )

	local f, xPos, yPos
	local dmc = obj.__dmc.multitouch
	local touches = dmc.touches
	local touchStack = dmc.touchStack

	-- create our event to dispatch
	local e = {
		name = MULTITOUCH_EVENT,
		phase = event.phase,

		target = obj
	}





	local calcs

	--== Start processing the Corona touch event ==--

	if event.phase == 'began' then

		--dmc.offsetX = obj.x - event.x
		--dmc.offsetY = obj.y - event.y

		-- fill in event and dispatch
		--e.moveX = obj.x
		--e.moveY = obj.y
		--obj:dispatchEvent( e )

		-- using hack as described here:
		-- http://developer.anscamobile.com/reference/index/objectaddeventlistener
		--
		--f = createObjectCallback( obj, finishPhaseBegan )
		--timer.performWithDelay( 1, f )



		if not touches[ event.id ] then

			touches[ event.id ] = event
			table.insert( touchStack, 1, event.id )
			--display.getCurrentStage():setFocus( obj, event.id )
			display.getCurrentStage():setFocus( obj )

			--[[
			while #touchStack > 2 do
				table.remove( touchStack, #touchStack )
			end
			--]]
		end

		--print( "TS ", #touchStack )

		if #touchStack >= 2 and not dmc.distanceTouch then
			calculateBase( obj )
		end

	elseif event.phase == 'moved' then


		-- fill in event and dispatch
		e.moveX = obj.x
		e.moveY = obj.y
		--obj:dispatchEvent( e )

		touches[ event.id ] = event
		--print( "TS ", #touchStack )

		if #touchStack >= 2 and dmc.distanceTouch then
			calcs = calculateDelta( obj )

			if dmc.doPinch then
				if calcs.scale > 0.25 and calcs.scale < 15 then
					obj.xScale = calcs.scale ; obj.yScale = calcs.scale
				end
			end
			obj.rotation = calcs.rotation

			obj.x = calcs.x ; obj.y = calcs.y

			local cO = debugObjs["objCenter"]
			cO.x = obj.x ; cO.y = obj.y


		end


		--[[
		print("DO")
		for k,v in pairs( touches ) do
			print( k,v )
		end
		--]]


	elseif ( event.phase == 'ended' or event.phase == 'canceled' ) then

		-- fill in event and dispatch
		e.moveX = obj.x
		e.moveY = obj.y
		--obj:dispatchEvent( e )

		if touches[event.id] then

			touches[event.id] = nil

			
			--display.getCurrentStage():setFocus( obj, nil )
			display.getCurrentStage():setFocus( nil )

			local i = 1
			while touchStack[i] do
				if touchStack[i] == event.id then
					table.remove (touchStack, i)
					break
				end
				i = i + 1
			end
		end



		if #touchStack >= 2 then
			calculateBase( obj )
		else
			dmc.distanceTouch = nil
		end

		--print( "TS ", #touchStack )


		-- using hack as described here:
		-- http://developer.anscamobile.com/reference/index/objectaddeventlistener
		--
		--f = createObjectCallback( obj, finishPhaseEnd )
		--timer.performWithDelay( 1, f )

	end

	return true

end




--===================================================================--
-- MultiTouch Object
--===================================================================--


local MultiTouch = {}


--== Constants ==--

--local MAX_LIMIT_ANGLE = 45

MultiTouch.MULTITOUCH_EVENT = MULTITOUCH_EVENT



--== Functions ==--


-- move()
--
-- blesses an object to have drag properties
--
-- @param obj a Corona-type object
-- @param params a Lua table with modifiers
-- @return the object which has been blessed (original), or nil on error
--
MultiTouch.bless = function( obj, params )

	params = params or {}

	-- sanity check
	if obj.__dmc and obj.__dmc.multitouch then
		print( "WARNING: only initialize Touch once !" )
		return nil
	end

	-- create our fancy callback and set event listener
	local f = createObjectCallback( obj, multitouchTouchHandler )
	obj:addEventListener( "touch", f )


	--== Setup special dmc_touch variables ==--

	if obj.__dmc == nil then obj.__dmc = {} end

	local dmc = {
		-- table to hold active touches, keyed on touch ID
		touches = {},
		touchStack = {},

		scaleOrig = nil,
		angleOrig = nil,

		midpointTouch = nil,
		distanceTouch = nil,
		angleTouch = nil,
		distanceCenter = nil,
		angleCenter = nil
	}
	dmc.doPinch = params.doPinch == nil and true or params.doPinch

	obj.__dmc.multitouch = dmc

	return obj

end

return MultiTouch

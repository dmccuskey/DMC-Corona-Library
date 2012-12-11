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

local VERSION = "0.3.0"


--===================================================================--
-- Imports
--===================================================================--

local TouchMgr = require( "dmc_touchmanager" )

--local Utils = require( "dmc_utils" )

--===================================================================--
-- Setup, Constants
--===================================================================--

local MULTITOUCH_EVENT = "multitouch_event"

local DEBUG = true

local debugObjs = {}


--===================================================================--
-- Triggr Class
--===================================================================--

local Triggr = {}

function Triggr:new()

	local o = {}
	local mt = { __index = Triggr }
	setmetatable( o, mt )

	--== Set Properties ==--
	o:reset()

	return o
end


function Triggr:reset()
	--print( "Triggr:reset" )

	self.quad = 0  -- 1,2,3,4 
	self.quad_cnt = 0 -- +/- num
	self.direction = 0 -- -1, 0, 1
	self.stateFunc = nil -- func to current state

	self.ang_base = 0 -- original angle
	self.ang_delta_base = 0 -- -ang/+ang
	self.ang_delta = 0 -- -ang/+ang
	self.ang_delta_sum = 0 -- -ang/+ang

	self.angle_sum = 0 -- -ang/+ang

end

function Triggr:start( x, y )
	local ang

	self:reset()

	self.quad, self.ang_base = self:_getQuad( x, y )

	if self.quad == 1 then
		self.stateFunc = self._quad_I
	elseif self.quad == 2 then
		self.stateFunc = self._quad_II
	elseif self.quad == 3 then
		self.stateFunc = self._quad_III
	elseif self.quad == 4 then
		self.stateFunc = self._quad_IV
	end
end

function Triggr:set( x, y )

	local new_quad, refang = self:_getQuad( x, y )

	self:stateFunc( new_quad, refang )

	self.angle_sum = self.ang_delta_base + self.ang_delta_sum + self.ang_delta

	--print( new_quad, Triggr.direction, Triggr.quad_cnt )
	--print( new_quad, Triggr.quad_cnt, ( Triggr.ang_delta_base + Triggr.ang_delta + Triggr.ang_delta_sum ), Triggr.ang_delta, Triggr.ang_delta_sum )

end


--== Private Methods ==--

function Triggr:_getQuad( x, y )
	--print( "Triggr:_getQuad", x, y )
	local q, ang, refang

	ang = math.deg( math.atan2( y, x ) )
	if x >= 0 and y >= 0 then
		q = 1
		refang = ang
	elseif x < 0 and y >= 0 then
		q = 2
		refang = 180 - ang
	elseif x < 0 and y < 0 then
		q = 3
		--refang = ang - 180
		refang = 180 + ang
	elseif x >= 0 and y < 0 then
		q = 4
		--refang = 360 - ang
		refang = -ang
	end

	return q, refang 
end

function Triggr:_quad_I( new_quad, refang )

	local curr_quad = self.quad
	local curr_quad_cnt = self.quad_cnt
	local ang_base = self.ang_base

	-- back, negative
	if new_quad == 2 then

		self.quad_cnt = self.quad_cnt - 1

		if curr_quad_cnt == 0 then
			self.ang_delta_base = self.ang_base - 90
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			self.ang_delta = 0 -- !!!!!!!!!!!!!!!!!!!

			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "I > II : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_II

		self:stateFunc( new_quad, refang )


	-- forward, positive
	elseif new_quad == 4 then

		self.quad_cnt = self.quad_cnt + 1

		if curr_quad_cnt == 0 then
			self.ang_delta_base = self.ang_base
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "I > IV : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_IV

		self:stateFunc( new_quad, refang )

	-- cross, positive
	elseif new_quad == 3 then

	-- current quadrant
	else

		-- we started here
		if curr_quad_cnt == 0 then
			self.ang_delta_base = 0

			if refang > ang_base then
				self.direction = -1
				self.ang_delta = self.ang_base - refang

			elseif refang < ang_base then
				self.direction = 1
				self.ang_delta = self.ang_base - refang

			else
				self.direction = 0
				self.ang_delta = 0
			end

		else
			-- TODO
			-- back, negative
			if self.direction == -1 then
				self.ang_delta = -refang

			-- forward, positive
			elseif self.direction == 1 then
				-- TODO
				self.ang_delta = 90 - refang

			end

		end

	end

end


function Triggr:_quad_II( new_quad, refang )

	local curr_quad = self.quad
	local curr_quad_cnt = self.quad_cnt
	local ang_base = self.ang_base

	local quad_multiple

	-- back, negative
	if new_quad == 3 then

		self.quad_cnt = self.quad_cnt - 1

		if curr_quad_cnt == 0 then
			self.ang_delta_base = -self.ang_base
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			self.ang_delta = 0

			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "II > III : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_III

		self:stateFunc( new_quad, refang )
	

	-- forward, positive
	elseif new_quad == 1 then

		self.quad_cnt = self.quad_cnt + 1

		if curr_quad_cnt == 0 then
			self.ang_delta_base = 90 - self.ang_base
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			self.ang_delta = 0

			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "II > I : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_I

		self:stateFunc( new_quad, refang )


	-- cross, positive
	elseif new_quad == 4 then

	-- current quadrant
	else

		-- we started here
		if curr_quad_cnt == 0 then
			self.ang_delta_base = 0

			if refang < ang_base then
				self.direction = -1
				self.ang_delta = -( self.ang_base - refang )

			elseif refang > ang_base then
				self.direction = 1
				self.ang_delta = -( self.ang_base - refang )

			else
				self.direction = 0
				self.ang_delta = 0
			end

		else
			-- back, negative
			if self.direction == -1 then
				self.ang_delta = refang - 90

			-- forward, positive
			elseif self.direction == 1 then
				self.ang_delta = refang

			end

		end

	end

end

function Triggr:_quad_III( new_quad, refang )

	local curr_quad = self.quad
	local curr_quad_cnt = self.quad_cnt
	local ang_base = self.ang_base

	-- back, negative
	if new_quad == 4 then

		self.quad_cnt = self.quad_cnt - 1

		if curr_quad_cnt == 0 then
			self.ang_delta_base = self.ang_base - 90
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "III > IV : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_IV

		self:stateFunc( new_quad, refang )


	-- forward, positive
	elseif new_quad == 2 then

		self.quad_cnt = self.quad_cnt + 1

		if curr_quad_cnt == 0 then
			self.ang_delta_base = self.ang_base
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "III > II : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_II

		self:stateFunc( new_quad, refang )


	-- cross, positive
	elseif new_quad == 1 then

	-- current quadrant
	else

		-- we started here
		if curr_quad_cnt == 0 then
			self.ang_delta_base = 0

			if refang > ang_base then
				self.direction = -1
				self.ang_delta = self.ang_base - refang

			elseif refang < ang_base then
				self.direction = 1
				self.ang_delta = self.ang_base - refang

			else
				self.direction = 0
				self.ang_delta = 0

			end


		else
			-- back, negative
			if self.direction == -1 then
				self.ang_delta = -refang

			-- forward, positive
			elseif self.direction == 1 then
				-- TODO
				self.ang_delta = 90 - refang

			end

		end

	end

end

function Triggr:_quad_IV( new_quad, refang )

	local curr_quad = self.quad
	local curr_quad_cnt = self.quad_cnt
	local ang_base = self.ang_base

	-- back, negative
	if new_quad == 1 then

		self.quad_cnt = self.quad_cnt - 1

		if curr_quad_cnt == 0 then
			self.ang_delta_base = self.ang_base - 90
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "IV > I : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_I

		self:stateFunc( new_quad, refang )


	-- forward, positive
	elseif new_quad == 3 then

		self.quad_cnt = self.quad_cnt + 1

		if curr_quad_cnt == 0 then
			-- TODO
			self.ang_delta_base = 90 - self.ang_base
			self.ang_delta = 0
			self.ang_delta_sum = 0
		else
			if self.quad_cnt == 0 then
				self.ang_delta_sum = 0
			else
				self.ang_delta_sum = self.direction * ( math.abs( self.quad_cnt ) - 1 ) * 90
			end
		end

		--print( "IV > III : ", math.abs( self.quad_cnt ), self.ang_delta_base, self.ang_delta_sum )

		self.quad = new_quad
		self.stateFunc = self._quad_III

		self:stateFunc( new_quad, refang )


	-- cross, positive
	elseif new_quad == 2 then

	-- current quadrant
	else

		-- we started here
		if curr_quad_cnt == 0 then
			self.ang_delta_base = 0

			if refang < ang_base then
				self.direction = -1
				self.ang_delta = -( self.ang_base - refang )

			elseif refang > ang_base then
				self.direction = 1
				self.ang_delta = -( self.ang_base - refang )

			else
				self.direction = 0
				self.ang_delta = 0

			end


		else
			-- back, negative
			if self.direction == -1 then
				self.ang_delta = refang - 90

			-- forward, positive
			elseif self.direction == 1 then
				self.ang_delta = refang

			end

		end

	end

end



--===================================================================--
-- Support Functions
--===================================================================--



if DEBUG then

	local obj

	-- blue spot over center of main object
	obj = display.newRect( 0, 0, 16, 16 )
	obj:setFillColor(0,0,255)
	obj:toFront()
	debugObjs["objCenter"] = obj

	-- green spot over midpoint center
	obj = display.newRect( 0, 0, 10, 10 )
	obj:setFillColor(0,255,0)
	obj:toFront()
	debugObjs["touchCenter"] = obj

	-- red spot over calculated center
	obj = display.newRect( 0, 0, 10, 10 )
	obj:setFillColor(255,0,0)
	obj:toFront()
	debugObjs["calcCenter"] = obj

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



-- createConstrainMoveFunc()
--
-- create function closure use to constrain movement
-- returns function to call
-- functions return :
-- ( xPos, yPos )
--
function createConstrainMoveFunc( dmc, params )

	local p = params or {}
	local f

	local SIN_45DEG = 0.707

	local xB = p.xBounds
	local yB = p.yBounds
	local cA = p.constrainAngle

	local sin_cA
	if cA then
		sin_cA = math.sin( math.rad( cA ) )
	end

	if cA and xB then

		f = function( xPos, yPos )

					local xDelta, yDelta			 	
				 	xPos = checkBounds( xPos, xB )
					xDelta = xPos - dmc.xOrig 
					yDelta = y_given_x_angle( xDelta, cA )
					yPos = yDelta + dmc.yOrig

					return xPos, yPos
				end

	elseif cA and yB then

		f = function( xPos, yPos )				 	

					local xDelta, yDelta			 	
				 	yPos = checkBounds( yPos, yB )
					yDelta = yPos - dmc.yOrig
					xDelta = x_given_y_angle( yDelta, cA )
					xPos = xDelta + dmc.xOrig

					return xPos, yPos
				end

	elseif cA and sin_cA <= SIN_45DEG then

		f = function( xPos, yPos )	

					local xDelta, yDelta			 	
					xDelta = xPos - dmc.xOrig 
					yDelta = y_given_x_angle( xDelta, cA )
					yPos = yDelta + dmc.yOrig

					return xPos, yPos
				end

	elseif cA and sin_cA > SIN_45DEG then

		f = function( xPos, yPos )	

					local xDelta, yDelta			 	
					yDelta = yPos - dmc.yOrig
					xDelta = x_given_y_angle( yDelta, cA )
					xPos = xDelta + dmc.xOrig

					return xPos, yPos
				end

	elseif xB and yB then

		f = function( xPos, yPos )

				 	xPos = checkBounds( xPos, xB )
				 	yPos = checkBounds( yPos, yB )

					return xPos, yPos
				end

	elseif xB then

		f = function( xPos, yPos )

				 	xPos = checkBounds( xPos, xB )
				 	
					return xPos, yPos
				end

	elseif yB then

		f = function( xPos, yPos )

				 	yPos = checkBounds( yPos, yB )

					return xPos, yPos
				end

	elseif not xB and not yB and not cA then

		f = function( xPos, yPos )
					return xPos, yPos
				end

	else
		print( "ERROR: you can't do that" )
	end

	return f

end

-- createConstrainScaleFunc()
--
-- create function closure use to constrain scaling
-- returns function to call
-- functions return either:
-- ( "MIN", value ) -- if under minimum, and min value
-- ( "MAX", value ) -- if over maximum, and max value
-- nil -- if value passes
--
function createConstrainScaleFunc( params )

	local p = params or {}
	local f

	if p.maxScale and p.minScale then
		f = function( value )
					if value < p.minScale then
						return "MIN", p.minScale
					elseif value > p.maxScale then
						return "MAX", p.maxScale
					end
					return nil
				end

	elseif p.minScale then
		f = function( value )
					if value < p.minScale then
						return "MIN", p.minScale
					end
					return nil
				end

	elseif p.maxScale then
		f = function( value )
					if value > p.maxScale then
						return "MAX", p.maxScale 
					end
					return nil
				end

	else
		f = function( value ) return nil end
	end

	return f

end


-- createConstrainScaleFunc()
--
-- create function closure use to constrain scaling
-- returns function to call
-- functions return either:
-- ( "MIN", value ) -- if under minimum, and min value
-- ( "MAX", value ) -- if over maximum, and max value
-- nil -- if value passes
--
function createConstrainRotateFunc( params )

	local p = params or {}
	local f

	if p.maxAngle and p.minAngle then
		f = function( value )
					if value < p.minAngle then
						return "MIN", p.minAngle
					elseif value > p.maxAngle then
						return "MAX", p.maxAngle
					end
					return nil
				end

	elseif p.minAngle then
		f = function( value )
					if value < p.minAngle then
						return "MIN", p.minAngle
					end
					return nil
				end

	elseif p.maxAngle then
		f = function( value )
					if value > p.maxAngle then
						return "MAX", p.maxAngle 
					end
					return nil
				end

	else
		f = function( value ) return nil end
	end

	return f

end



local function getSingleCalcFunc( obj )
	--print( "getSingleCalcFunc" )

	local dmc = obj.__dmc.multitouch
	--print( "<<<<<<<<<< calculateDelta" )
	local touches = dmc.touches
	local touchStack = dmc.touchStack
	local action

	local t1 = touches[ touchStack[1] ]
	local diff = { x=t1.x-obj.x, y=t1.y-obj.y }

	return function()

		local mid

		t1 = touches[ touchStack[1] ]

		-- only time when this is true
		action = dmc.actions[ 'move' ]
		if action and action[ 'single' ] == true then
			mid = { x=t1.x-diff.x, y=t1.y-diff.y }
		else
			mid = { x=obj.x, y=obj.y }
		end

		return t1, mid
	end

end

local function getMultiCalcFunc( obj )
	--print( "getMultiCalcFunc" )
	local dmc = obj.__dmc.multitouch
	--print( "<<<<<<<<<< calculateDelta" )
	local touches = dmc.touches
	local touchStack = dmc.touchStack

	local t1, t2

	return function()

		local dx, dy
		local mid

		t1 = touches[ touchStack[1] ]
		t2 = touches[ touchStack[2] ]

		dx = t1.x - t2.x
		dy = -( t1.y - t2.y )

		mid = { x=t1.x-dx/2, y=t1.y+dy/2 }

		return t1, mid
	end

end


local function calculateBase( obj )
	--print( "======== calculateBase" )
	local dmc = obj.__dmc.multitouch
	local touches = dmc.touches
	local touchStack = dmc.touchStack

	local cO -- corona obj

	local dx, dy
	local x, y

	local midpoint, touch

	touch, midpoint = dmc.touchFunc()
	
	dmc.midpointTouch = midpoint


	if DEBUG then
		-- update touch center point
		cO = debugObjs["touchCenter"]
	 	cO.x = dmc.midpointTouch.x ; cO.y = dmc.midpointTouch.y
		--print( dmc.midpointTouch.x, dmc.midpointTouch.y )
	end

	-- save current properties
	dmc.scaleOrig = obj.xScale
	dmc.angleOrig = -obj.rotation -- convert from Corona to trig angles
	dmc.xOrig = obj.x
	dmc.yOrig = obj.y

	-- save distance, angle between touches
	dx = touch.x - midpoint.x
	dy = -( touch.y - midpoint.y )
	
	dmc.triggr:start( dx, dy )


	--dmc.distanceTouch = math.sqrt( dx*dx + dy*dy )
	dmc.distanceTouch = math.sqrt( dx*dx + dy*dy )
	--print( dx, dy )

	-- calculate direction
	dmc.lastRotation = 0
	dmc.lastDirection = nil
	--print( 'distance ', dx, dy, dmc.distanceTouch )
	--print( "angle ", dmc.angleOrig )


	-- center point calculations
	dx = obj.x - dmc.midpointTouch.x
	dy = -( obj.y - dmc.midpointTouch.y )


	--print( display.contentWidth, display.contentHeight )
	--print( dmc.midpointTouch.x, obj.x )
	dmc.distanceCenter = math.sqrt( dx*dx + dy*dy )
	dmc.angleCenter = math.deg( math.atan2( dy, dx ) )
	--print( "dco: ", dmc.distanceCenter )
	--print( "aco: ", dmc.angleCenter ) -- trig angle
	--print( "obj: ", dmc.scaleOrig, obj.x, obj.y )


	x = math.cos( math.rad( dmc.angleCenter ) ) * dmc.distanceCenter + dmc.midpointTouch.x
	y = math.sin( math.rad( -dmc.angleCenter ) ) * dmc.distanceCenter + dmc.midpointTouch.y

	--print( "objx.y: ", obj.x, obj.y )
	--print( "x.y: ", x, y )

	if DEBUG then
		cO = debugObjs["calcCenter"]
		cO.x = x ; cO.y = y
	end

	-- pack up results
	local ret = {
		scale = dmc.scaleOrig,
		rotation = obj.rotation,
		x = obj.x,
		y = obj.y,

		-- dispatch events
		direction = dmc.lastDirection,
		angleDelta = 0, -- convert to Corona angle
		distanceDelta = 0,
		xDelta = 0,
		yDelta = 0
	}

	return ret
end


local function calculateDelta( obj )
	local dmc = obj.__dmc.multitouch
	--print( "<<<<<<<<<< calculateDelta" )
	local touches = dmc.touches
	local touchStack = dmc.touchStack

	local cO -- corona obj
	local dx, dy
	local x, y
	local action

	touch, midpoint = dmc.touchFunc()
	
	dmc.midpointTouch = midpoint


	if DEBUG then
		-- update touch center point
		cO = debugObjs["touchCenter"]
	 	cO.x = dmc.midpointTouch.x ; cO.y = dmc.midpointTouch.y
		--print( dmc.midpointTouch.x, dmc.midpointTouch.y )
	end

	dx = touch.x - midpoint.x
	dy = -( touch.y - midpoint.y )


	-- calculate new distance between touches and scale
	local d, scale, scaled
	action = dmc.actions[ 'scale' ]
	if action and not action[ dmc.activeTouch ] then
		scale = 1.0
		scaled = dmc.scaleOrig
	else
		d = math.sqrt( dx*dx + dy*dy )
		scale = d / dmc.distanceTouch
		scaled = scale * dmc.scaleOrig
		--print( 'distance ', scale, dx, dy, dmc.distanceTouch, d )
	end


	-- calculate new angle
	dmc.triggr:set( dx, dy )
	local angleDiff = -dmc.triggr.angle_sum -- negative is clockwise
	local rotation = -( dmc.angleOrig + angleDiff )
	--print( "angle: ", angleDiff, dmc.triggr.angle_sum )

	-- calculate direction
	local rotationDiff = dmc.lastRotation - angleDiff
	if rotationDiff < 0 then 
		dmc.lastDirection = "counter_clockwise"
	elseif rotationDiff > 0 then
		dmc.lastDirection = "clockwise"
	end	
	dmc.lastRotation = angleDiff


	-- calculate new position
	x = dmc.midpointTouch.x + math.cos( math.rad( -( dmc.angleCenter + angleDiff ) ) ) * ( dmc.distanceCenter * scale )
	y = dmc.midpointTouch.y + math.sin( math.rad( -( dmc.angleCenter + angleDiff ) ) ) * ( dmc.distanceCenter * scale )
	--print( "x.y: ", x, y )

	local xDiff = x - dmc.xOrig
	local yDiff = y - dmc.yOrig

	if DEBUG then
		cO = debugObjs["calcCenter"]
		cO.x = x
		cO.y = y
	end


	-- pack up results
	local ret = {
		scale = scaled,
		rotation = rotation,
		x = x,
		y = y,

		-- dispatch events
		direction = dmc.lastDirection,
		angleDelta = -angleDiff, -- convert to Corona angle
		distanceDelta = d,
		xDelta = xDiff,
		yDelta = yDiff
	}

	return ret

end


function updateObject( obj, phase, params )

	local dmc = obj.__dmc.multitouch

	local action, res, val


	--== move ==--

	action = dmc.actions[ 'move' ] 
	if action and action[ dmc.activeTouch ] then
		xPos, yPos = action.func( params.x, params.y )

		obj.x = xPos ; obj.y = yPos
	end

	--== scale ==--

	action = dmc.actions[ 'scale' ] 
	if action and action[ dmc.activeTouch ] then
		res, val = action.func( params.scale )

		if res == "MAX" then
			obj.xScale = val ; obj.yScale = val
		elseif res == "MIN" then
			obj.xScale = val ; obj.yScale = val
		else
			obj.xScale = params.scale ; obj.yScale = params.scale
		end
	end

	--== rotate ==--

	action = dmc.actions[ 'rotate' ] 
	if action and action[ dmc.activeTouch ] then
		res, val = action.func( params.rotation )

		if res == "MAX" then
			obj.rotation = val
		elseif res == "MIN" then
			obj.rotation = val
		else
			obj.rotation = params.rotation
		end
	end

end




function multitouchTouchHandler( event )
	--print( "multitouchTouchHandler", event.id )

	local f, xPos, yPos, cO, calcs, beginPoints

	local obj = event.target
	local dmc = obj.__dmc.multitouch
	local touches = dmc.touches
	local touchStack = dmc.touchStack

	-- create our event to dispatch
	local e = {
		name = MULTITOUCH_EVENT,
		phase = event.phase,

		target = obj
	}

	--== Start processing the Corona touch event ==--

	if event.phase == 'began' then

		-- check to see if we have room to add this new touch event
		if ( ( dmc.isSingleActive and #touchStack == 1 and not dmc.isMultiActive ) or 
				( dmc.isMultiActive and #touchStack == 2 ) ) then

			-- we're not doing anything with this touch event
			return false
		end

		touches[ event.id ] = event
		TouchMgr:setFocus( event.target, event.id )
		table.insert( touchStack, 1, event.id )

		--Utils.print( event )
		--print( #touchStack )

		-- create function to pre-process touch gestures
		if ( dmc.isSingleActive and #touchStack == 1 ) then
			dmc.touchFunc = getSingleCalcFunc( obj )
			dmc.activeTouch = 'single'

		elseif ( dmc.isMultiActive and #touchStack == 2 ) then
			dmc.touchFunc = getMultiCalcFunc( obj )
			dmc.activeTouch = 'multi'

		else 
			dmc.touchFunc = nil
			dmc.activeTouch = nil

		end

		-- process the gesture
		if dmc.touchFunc then

			calcs = calculateBase( obj )

			-- fill in event and dispatch
			e.direction = calcs.direction
			e.angleDelta = calcs.angleDelta
			e.distanceDelta = calcs.distanceDelta
			e.xDelta = calcs.xDelta ; e.yDelta = calcs.yDelta
			e.x = calcs.x ; e.y = calcs.y

			if obj.dispatchEvent ~= nil then
				obj:dispatchEvent( e )
			end


			if DEBUG then
				cO = debugObjs["touchCenter"]
				cO.isVisible = true
				cO = debugObjs["calcCenter"]
				cO.isVisible = true
			end

		end

		return true

	elseif event.phase == 'moved' then

		-- if we are in control of this touch ID
		if event.isFocused then
			touches[ event.id ] = event

			-- process the gesture
			if dmc.touchFunc then

				calcs = calculateDelta( obj )
				updateObject( obj, event.phase, calcs )

				-- fill in event and dispatch
				e.direction = calcs.direction
				e.angleDelta = calcs.angleDelta
				e.distanceDelta = calcs.distanceDelta
				e.xDelta = calcs.xDelta ; e.yDelta = calcs.yDelta
				e.x = calcs.x ; e.y = calcs.y

				if obj.dispatchEvent ~= nil then
					obj:dispatchEvent( e )
				end

				if DEBUG then
					--print( calcs.angleDelta )
					cO = debugObjs["objCenter"]
					cO.x = obj.x ; cO.y = obj.y
				end

			end

			return true

		end


	elseif ( event.phase == 'ended' or event.phase == 'canceled' ) then

		if event.isFocused then

			touches[ event.id ] = event

			if dmc.touchFunc then

				calcs = calculateDelta( obj )
				updateObject( obj, event.phase, calcs )

				-- fill in event and dispatch
				e.direction = calcs.direction
				e.angleDelta = calcs.angleDelta
				e.distanceDelta = calcs.distanceDelta
				e.xDelta = calcs.xDelta ; e.yDelta = calcs.yDelta
				e.x = calcs.x ; e.y = calcs.y

				if obj.dispatchEvent ~= nil then
					obj:dispatchEvent( e )
				end

			end

			TouchMgr:unsetFocus( event.target, event.id )

			-- remove event from our structures
			touches[ event.id ] = nil

			local i = 1
			while touchStack[i] do
				if touchStack[i] == event.id then
					table.remove (touchStack, i)
					break
				end
				i = i + 1
			end


			-- create function to pre-process touch gestures
			if ( dmc.isSingleActive and #touchStack == 1 ) then
				dmc.touchFunc = getSingleCalcFunc( obj )
				dmc.activeTouch = 'single'

			elseif ( dmc.isMultiActive and #touchStack == 2 ) then
				dmc.touchFunc = getMultiCalcFunc( obj )
				dmc.activeTouch = 'multi'

			else 
				dmc.touchFunc = nil
				dmc.activeTouch = nil

			end

			-- process the gesture
			if dmc.touchFunc then
				calculateBase( obj )

			else
				if DEBUG then
					cO = debugObjs["touchCenter"]
					cO.isVisible = false
					cO = debugObjs["calcCenter"]
					cO.isVisible = false
				end				
			end

			return true

		end -- event.isFocused

	end -- event.phase == ended


	return false

end




--===================================================================--
-- MultiTouch Object
--===================================================================--


local MultiTouch = {}


--== Constants ==--

MultiTouch.MULTITOUCH_EVENT = MULTITOUCH_EVENT


--== Support Functions ==--

-- sets isSingleActive, isMultiActive
-- returns table with keys: 'single', 'multi', 'func'
--
function processParameters( dmc, action, touchtype, params )
	--print( "processParameters", action )

	local config = {}

	-- constrain function

	if action == 'move' then
		config.func = createConstrainMoveFunc( dmc, params )
	elseif action == 'scale' then
		config.func = createConstrainScaleFunc( params )
	elseif action == 'rotate' then
		config.func = createConstrainRotateFunc( params )
	else
		print( "WARNING: unknown action: " .. action )
		return nil
	end

	-- active touches

	config[ 'single' ] = false
	config[ 'multi' ] = false

	if type( touchtype ) == 'string' then
		config[ touchtype ] = true

	elseif type( touchtype ) == 'table' then

		for _, v in ipairs( touchtype ) do
			if type( v ) == 'string' then
				config[ v ] = true
			end
		end

	end

	return config
end

--== Main Functions ==--


-- move()
--
-- blesses an object to have drag properties
--
-- @param obj a Corona-type object
-- @param params a Lua table with modifiers
-- @return the object which has been blessed (original), or nil on error
--
MultiTouch.activate = function( obj, action, touchtype, params )

	params = params or {}

	-- create our fancy callback and set event listener
	TouchMgr:register( obj, multitouchTouchHandler )

	--== Setup special dmc_touch variables ==--

	local dmc
	if obj.__dmc == nil then obj.__dmc = {} end

	if obj.__dmc.multitouch then
		dmc = obj.__dmc.multitouch

	else

		dmc = {
			-- table to hold active touches, keyed on touch ID
			touches = {},
			touchStack = {},
			activeTouch = nil, -- 'multi', 'single', nil
			touchFunc = nil, -- calculates mid point and touch
			actions = {}, -- holds 'move', 'rotate', 'scale' configurations

			scaleOrig = nil,
			angleOrig = nil,
			xOrig = nil,
			yOrig = nil,

			midpointTouch = nil,
			distanceTouch = nil,
			distanceCenter = nil,
			angleCenter = nil,
			angleAgent = nil,

			-- to calculate direction in broadcast event
			lastRotation = nil,
			lastDirection = nil
		}


		dmc.triggr = Triggr:new()

		obj.__dmc.multitouch = dmc
	end

	--== Process Parameters ==--

	local config = processParameters( dmc, action, touchtype, params )
	local configIsOK = true
	local dmc_action

	-- check for conflics (with single touch actions)
	if action == 'move' and config[ 'single' ] then
		dmc_action = dmc.actions[ 'rotate' ]
		if dmc_action and dmc_action[ 'single' ] then configIsOK = false end;
		dmc_action = dmc.actions[ 'scale' ]
		if dmc_action and dmc_action[ 'single' ] then configIsOK = false end;

	elseif action == 'rotate' and config[ 'single' ] then
		dmc_action = dmc.actions[ 'move' ]
		if dmc_action and dmc_action[ 'single' ] then configIsOK = false end;

	elseif action == 'scale' and config[ 'single' ] then
		dmc_action = dmc.actions[ 'move' ]
		if dmc_action and dmc_action[ 'single' ] then configIsOK = false end;

	end

	if configIsOK then
			dmc.actions[ action ] = config
	else
		print( "\nERROR: '" .. action .. "' is not compatible with the current config: \n" )
	end


	-- set isSingleActive, isMultiActive, after setting any new actions

	dmc.isSingleActive = false
	dmc.isMultiActive = false

	-- ['move']={ single, multi, func }
	for _, v in ipairs( { 'move', 'rotate', 'scale' } ) do
		if dmc.actions[ v ] then
			if dmc.actions[ v ][ 'single' ] == true then
				dmc.isSingleActive = true
			end
			if dmc.actions[ v ][ 'multi' ] == true then
				dmc.isMultiActive = true
			end
		end
	end

	return obj

end


MultiTouch.deactivate = function( obj )

	local dmc = obj.__dmc.multitouch
	obj.__dmc.multitouch = nil

	TouchMgr:unregister( obj, multitouchTouchHandler )

end


return MultiTouch

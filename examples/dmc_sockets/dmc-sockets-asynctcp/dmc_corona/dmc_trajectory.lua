--====================================================================--
-- dmc_trajectory.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_trajectory.lua
--====================================================================--

--[[

Copyright (C) 2012-2014 David McCuskey. All Rights Reserved.

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



--====================================================================--
-- DMC Corona Library : DMC Trajectory
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.1.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


--====================================================================--
-- Support Functions

local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

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


--====================================================================--
-- Configuration

local dmc_lib_data, dmc_lib_info

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_corona_boot" ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_library



--====================================================================--
-- DMC Trajectory
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_trajectory = dmc_lib_data.dmc_trajectory or {}

local DMC_TRAJECTORY_DEFAULTS = {
}

local dmc_trajectory_data = Utils.extend( dmc_lib_data.dmc_trajectory, DMC_TRAJECTORY_DEFAULTS )



--====================================================================--
-- Setup, Constants

local gGRAVITY = 9.8
local RAD_TO_DEG = 180 / math.pi


--====================================================================--
-- Support Functions

-- createAngleIterator()
-- returns a function which calculates the angle of the trajectory
-- at a certain time in the trajectory path
--
local function createAngleIterator( Vx, Vy, params )
	--print( "createAngleIterator" )
	local func, f1, f2
	local xP, yP -- previous
	local adjust

	params = params == nil and {} or params
	local dir = params.direction == nil and "right" or params.direction


	-- adjust for direction that object is facing, if necessary
	if dir == "right" then
		if Vx > 0 then adjust = 0 else adjust = 180 end
	else
		if Vx > 0 then adjust = 180 else adjust = 0 end
	end


	-- this one is only good for first calculation
	f1 = function( x, y )

		local r2d = RAD_TO_DEG -- make a little faster ?

		xP, yP = x, y -- save for next calc
		func = f2 -- switch calc func

		-- return negative to compensate for difference
		-- in physics angles and Corona angles
		return ( - math.atan( Vy / Vx ) * r2d ) + adjust
	end

	-- this will do all of the rest of the calculations
	f2 = function( x, y )

		local r2d = RAD_TO_DEG -- make a little faster ?
		local xD, yD = x - xP, y - yP
		--print( "in f2", x, xD, y, yD )

		xP, yP = x, y -- save for next calc

		-- return negative to compensate for difference
		-- in physics angles and Corona angles
		return ( - math.atan( yD / xD ) * r2d ) + adjust
	end

	func = f1

	local f = function( x, y )
		return func( x, y )
	end

	return f
end



-- performTransition()
-- creates and runs a function which calculates and controls moving an object
-- through a parabolic/ballistic path
--
-- obj (Corona Object): the object to move
-- ballistic (table): table of params
-- transition (table): table of params
--
local function performTransition( obj, ballistic, transition )
	--print( "performTransition" )

	--== Vars to be saved between calls ==--

	local halfG = 0.5 * gGRAVITY
	local positionIterator, angleIterator

	local Ts = 0  -- start time

	local pB, pE = transition.pB, transition.pE
	local Vx, Vy = ballistic.Vx, ballistic.Vy
	-- Tbt - total ballistic time
	-- Ttt - total transition time
	local Tbt, Ttt = ballistic.Tbt, transition.Ttt
	local onComplete = transition.onComplete


	-- create iterator to rotate object

	if transition.rotate == true then
		angleIterator = createAngleIterator( Vx, Vy, transition )
	else
		angleIterator = function( x, y ) return obj.rotation end
	end


	-- create the iterator to control the transition

	positionIterator = function( event )

		-- save time at which transition started
		if Ts == 0 then Ts = event.time end

		-- vars
		local xD, yD -- x,y difference
		local ang
		local Tt, Tb -- time transition, time ballistic

		-- calculate how long we have been running
		-- this is milliseconds past
		Tt = event.time - Ts

		if Tt < Ttt then
			--== still time in transition ==--

			-- calculate ballistic time given Corona time
			Tb = Tt / Ttt * Tbt

			-- calculate relative position and angle of projectile
			-- remove function calls to make a little faster
			-- xD = xGiven_vx_t( Vx, Tb )
			xD = Vx * Tb
			--yD = yGiven_vy_t( Vy, Tb )
			yD = Vy * Tb - halfG * Tb * Tb

			ang = angleIterator( xD, yD ) -- don't round x,y for this calc

			-- round off numbers for display purposes
			--xD = math.round( xD )
			--yD = math.round( yD )

			-- move object using relative coords
			obj.x = pB[1] + xD ; obj.y = pB[2] - yD
			obj.rotation = ang

		else
			--== transition time is over ==--

			-- move object to last position
			obj.x = pE[1] ; obj.y = pE[2]
			xD = pE[1] - pB[1] ; yD = pB[2] - pE[2]
			obj.rotation = angleIterator( xD, yD )

			-- clean up - stop motion, release iterator memory
			Runtime:removeEventListener( "enterFrame", positionIterator )
			positionIterator = nil ; angleIterator = nil

			-- perform callback if it exists
			if onComplete then onComplete() end
		end

	end

	-- start motion
	Runtime:addEventListener( "enterFrame", positionIterator )

end


--====================================================================--
-- Trajectory Object Setup
--====================================================================--

local Trajectory = {}


-- t_Given_Vy_pB_pE()
-- calculate time to move given distance, Y direction
--
-- Vy (int): initial velocity m/s
-- pB (table): x,y coordinates for start point
-- pE (table): x,y coordinates for end point
--
-- returns (number): time in seconds
--
function Trajectory.t_Given_Vy_pB_pE( Vy, pB, pE )

	local Vyd -- velocity at destination
	local Dy = pE[2] - pB[2]  -- distance between points, Y direction
	local t

	-- velocity at target, to help calculate time
	Vyd = math.sqrt( math.pow( Vy, 2 ) + 2 * gGRAVITY * Dy )
	--print( "dy, vy, vy ", Dy, Vyd, Vy )

	-- calculate time to complete trajectory
	-- eq: -v = u + -gt
	-- t = (-v-u) / -g
	t = ( -Vyd - Vy ) / - gGRAVITY

	return t

end


-- Vx_Given_t_pB_pE
-- static method to calculate the velocity in the x direction
-- given the time and the initial points
--
-- t (int): time in seconds
-- pB (table): x,y coordinates for start point
-- pE (table): x,y coordinates for end point
--
-- returns (number): velocity in m/s, x direction
--
function Trajectory.Vx_Given_t_pB_pE( t, pB, pE )
	local Dx = pE[1] - pB[1]  -- distance between points, X direction
	return Dx / t
end

-- Vy_Given_h()
-- static method to calculate Vy given max height / pure vertical component
--
-- h (int): height in meters
--
-- returns (int): velocity in m/s, y direction
--
function Trajectory.Vy_Given_h( h )
	return math.sqrt( h * gGRAVITY * 2 )
end

-- x_Given_vx_t()
-- static method to calculate x location given velocity and time
--
-- Vx (int): velocity in x direction, m/s
-- t (int): time in seconds
--
-- returns (int): distance in meters, x direction
--
function Trajectory.x_Given_vx_t( Vx, t )
	return Vx * t
end

-- y_Given_vy_t()
-- static method to calculate y distance given initial velocity and time
--
-- Vy (int): velocity in y direction, m/s
-- t (int): time in seconds
--
-- returns (int): distance in meters, Y direction
--
function Trajectory.y_Given_vy_t( Vy, t )
	return Vy * t - 0.5 * gGRAVITY * t * t
end


--== Main Methods ==--

-- calculate()
-- static method to calculate different parameters for the trajectory
-- required to fit within the parameters given
--
-- params (table): contains the following properties:
--
-- pBegin (table): x,y coordinates of point for beginning of transition
-- pEnd (table): x,y coordinates of point for end of transition
-- height (int): top of trajectory in pixels, measured from the highest of the points
--
function Trajectory.calculate( params )

	local pB, pE, Yd = params.pBegin, params.pEnd, params.height

	-- if end point is higher than begin point
	if pE[2] < pB[2] then Yd = Yd + ( pB[2] - pE[2] ) end

	-- do calculations to complete required trajectory
	local Vy = Trajectory.Vy_Given_h( Yd )
	local t = Trajectory.t_Given_Vy_pB_pE( Vy, pB, pE  )
	local Vx = Trajectory.Vx_Given_t_pB_pE( t, pB, pE  )
	local angIter = createAngleIterator( Vx, Vy, params )


	-- results of calculation
	return {
		Vx = Vx,
		Vy = Vy,
		time = t,
		angle = angIter() -- get first iteration
	}
end


-- move()
-- this static method gets calculations, cleans up params and starts the transition
--
-- obj (Corona Object): the object to move
-- params (table): contains the following properties:
--
-- time (int): duration of transition in milliseconds
-- pBegin (table): x,y coordinates of point for beginning of transition
-- pEnd (table): x,y coordinates of point for end of transition
-- height (int): top of trajectory in pixels, measured from the highest of the points
-- rotate (boolean): whether or not to rotate object automatically
-- onComplete (function): function to call at end of transition
--
function Trajectory.move( obj, params )

	local ballisticParams, transitionParams

	local rO = params.rotate ~= nil and params.rotate or false
	local r = Trajectory.calculate( params )

	ballisticParams = {
		Vx=r.Vx,
		Vy=r.Vy,
		Tbt=r.time
	}

	transitionParams = {
		Ttt = params.time,
		pB = params.pBegin,
		pE = params.pEnd,
		rotate = rO,
		onComplete = params.onComplete,
		direction = params.direction
	}

	-- create and run iterator to perform the transition
	performTransition( obj, ballisticParams, transitionParams )
end


return Trajectory

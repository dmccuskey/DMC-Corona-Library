--====================================================================--
-- Example: Trajectory Direction
--
-- Shows example of how to setup dmc_trajectory with objects
--  that face either left or right.
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
--
-- Copyright (C) 2012-2014 David McCuskey. All Rights Reserved.
--====================================================================--

print("---------------------------------------------------")

--=========================================================
-- Imports
--=========================================================

local Trajectory = require( "dmc_library.dmc_trajectory" )


--====================================================================--
-- Setup, Constants
--====================================================================--

display.setStatusBar( display.HiddenStatusBar )
math.randomseed( os.time() )


-- coordinate points for each test location
--
local POINTS = {
	{ 80, 120 }, { 240, 120 },
	{ 80, 240 }, { 240, 240 },
	{ 80, 360 }, { 240, 360 }
}
local CENTER_POINT = { 160, 240 }

-- tables of values, used for random choices
--
local HEIGHTS = { 5, 25, 45, 65 }
local TIMES = { 750, 1500, 3000 }


local grid = display.newGroup()


--====================================================================--
-- Support Functions
--====================================================================--

-- drawGrid()
-- create and position the grid points - locations for trajectory tests
--
local function drawGrid()
	local o

	for i=1, #POINTS do
		o = display.newCircle( POINTS[i][1], POINTS[i][2], 3 )
		grid:insert( o )
	end

	-- center point
		o = display.newCircle( CENTER_POINT[1], CENTER_POINT[2], 1 )
		grid:insert( o )
end



--== Projectile Creation functions ==--
--
local createLeftProjectile = function()
	local o = display.newImageRect( "assets/projectile_left.png", 12, 12 )
	local p = { rotate=true, direction="left" }
	return o, p
end
local createRightProjectile = function()
	local o = display.newImageRect( "assets/projectile_right.png", 13, 7 )
	local p = { rotate=true, direction="right" }
	return o, p
end


-- createRandomProjectile()
-- returns a random projectile
--
local function createRandomProjectile()

	if math.random( 2 ) == 1 then
		return createLeftProjectile()
	else
		return createRightProjectile()
	end

end



-- doTest()
--
local function doTest()

	local oB, oE, oP -- refs to objects Begin, End, Projectile
	local height, time -- random height and time for transition
	local pB, pE -- begin and end points for transition
	local prms, params -- params for transition call

	pB = CENTER_POINT

	-- get random items for transition
	pE = POINTS[ math.random( #POINTS ) ]
	height = HEIGHTS[ math.random( #HEIGHTS ) ]
	time = TIMES[ math.random( #TIMES ) ]


	-- begin point - green
	oB = display.newCircle( pB[1], pB[2], 1 )
	oB:setFillColor( 0, 1, 0 )

	-- end point -- red
	oE = display.newCircle( pE[1], pE[2], 5 )
	oE:setFillColor( 1, 0, 0 )

	-- projectile
	oP, prms = createRandomProjectile()
	oP.x, oP.y = pB[1], pB[2]


	-- onComplete function, called after trajectory transition is finished
	local onCompleteCallback = function()

		-- clean up test items
		oB:removeSelf()
		oE:removeSelf()
		oP:removeSelf()

		-- start a new test
		doTest()

	end

	-- setup params for our trajectory calls
	params = {
		time=time, pBegin=pB, pEnd=pE, height=height,
		rotate=prms.rotate, direction=prms.direction,
		onComplete=onCompleteCallback
	}

	-- get calculated angle for intiial setup
	prms = Trajectory.calculate( params )
	oP.rotation = prms.angle

	-- pause a bit so we can see setup

	timer.performWithDelay( 500, function()
		-- Do the transition
		Trajectory.move( oP, params )
	end)

end


--== Main Function

local main = function()
	drawGrid()
	doTest()
end

-- let's get this party started !
--
main()


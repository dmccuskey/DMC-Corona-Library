--====================================================================--
-- Trajectory Multiple
--
-- demonstrates multiple objects being controlled at a single time.
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License

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
	{ 80, 120 }, { 160, 120 }, { 240, 120 },
	{ 80, 240 }, { 160, 240 }, { 240, 240 },
	{ 80, 360 }, { 160, 360 }, { 240, 360 }
}

-- tables of values, used for random choices
--
local HEIGHTS = { 5, 25, 45, 65 }
local TIMES = { 500, 750, 1000, 2000 }

local grid = display.newGroup()


--====================================================================--
-- Support Functions
--====================================================================--

local doTransition, startTest -- forward declare functions


-- drawGrid()
-- create and position the grid points - locations for trajectory tests
--
local function drawGrid()
	local o

	for i=1, #POINTS do
		o = display.newCircle( POINTS[i][1], POINTS[i][2], 3 )
		grid:insert( o )
	end
end

-- doTransition()
-- recursive function which sets up test points with colored markers and runs a transition
--
-- list (table}: array of array of point pairs
-- eg { { {0,100}, {10,100} }, { {0,100}, {20,100} }, ... }
-- createProjectile (function ref): function to call to create a projectile object
-- params (table): table of parameters to pass in
--
function doTransition( list, createProjectile, params )

	local oB, oE, oP -- object Begin, End, Projectile
	local height, time --  random height and time for transition
	-- get next set of point pairs
	local pB, pE = unpack( table.remove( list ) )

	-- clean up params if necessary
	local params = params == nil and {} or params
	local rotate = params.rotate


	-- begin point - green
	oB = display.newCircle( pB[1], pB[2], 5 )
	oB:setFillColor( 0, 1, 0 )

	-- end point -- red
	oE = display.newCircle( pE[1], pE[2], 5 )
	oE:setFillColor( 1, 0, 0 )

	-- projectile
	oP = createProjectile()
	oP.x, oP.y = pB[1], pB[2]


	-- onComplete function, called after trajectory transition is finished
	local complete = function()

		-- clean up test items
		oB:removeSelf()
		oE:removeSelf()
		oP:removeSelf()

		-- see if anything left in the list of Point Pairs
		if #list > 0 then
			doTransition( list, createProjectile, params )
		else
			-- start over
			startTest( createProjectile, params )
		end
	end

	-- get random height and time for next transition
	height = HEIGHTS[ math.random( #HEIGHTS ) ]
	time = TIMES[ math.random( #TIMES ) ]

	-- DO IT !!
	Trajectory.move( oP, { time=time, pBegin=pB, pEnd=pE, height=height, rotate=rotate, onComplete=complete } )
end


-- startTest()
-- creates the list of Point Pairs to test, skipping pairs which are the same
-- calls recursive function doTransition with list for processing
--
function startTest( projectileFunction, params )

	local point_list = {}

	-- create list
	for i=#POINTS, 1, -1 do
		for j=#POINTS, 1, -1 do
			if i ~= j then
				table.insert( point_list, { POINTS[i], POINTS[j] } )
			end
		end
	end

	-- do test
	doTransition( point_list, projectileFunction, params )

end


--== Projectile Creation functions ==--
--
local createBlueRoundProjectile = function()
	local o = display.newCircle( 0, 0, 5 )
	o:setFillColor( 0, 0, 1 )
	return o
end
local createPurpleRectProjectile = function()
	local o = display.newRect( -4, -1, 8, 2 )
	o:setFillColor( 1, 0, 1 )
	return o
end
local createYellowRectProjectile = function()
	local o = display.newRect( -5, -2, 10, 4 )
	o:setFillColor( 1, 1, 0 )
	return o
end


--== Main Function

local main = function()

	drawGrid()

	--== Show multiple transitions ==--

	-- start test 1
	startTest( createBlueRoundProjectile )

	-- start test 2, 15s delay
	timer.performWithDelay( 10000, function()
		startTest( createPurpleRectProjectile, { rotate=true } )
	end )

	-- start test 3, 30s delay
	timer.performWithDelay( 20000, function()
		startTest( createYellowRectProjectile, { rotate=true } )
	end )

end

-- let's get this party started !
--
main()


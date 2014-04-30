--====================================================================--
-- Trajectory Basic
--
-- Shows simple trajectory using a single object.
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
--
-- Copyright (C) 2012-2014 David McCuskey. All Rights Reserved.
--====================================================================--

print("---------------------------------------------------")

--====================================================================--
-- Imports
--====================================================================--

local Trajectory = require( "dmc_library.dmc_trajectory" )


--====================================================================--
-- Setup, Constants
--====================================================================--

display.setStatusBar( display.HiddenStatusBar )

local BEGIN_POINT = { 80, 120 }
local END_POINT = { 240, 240 }

local gProjectile = nil -- ref to our global projectile object
local is_active = false -- flag for projectile motion, used for button


--====================================================================--
-- Support Functions
--====================================================================--

-- setupTransition()
-- create our projectile and position it at beginning location
--
local function setupTransition()

	gProjectile = display.newCircle( 0, 0, 5 )
	gProjectile:setFillColor( 0, 0, 1 )
	gProjectile.x, gProjectile.y = BEGIN_POINT[1], BEGIN_POINT[2]

end


-- doTransition()
-- run the transition and cleanup
--
local function doTransition()

	local onCompleteCallback = function()
		-- clean up items and setup for a new button press

		gProjectile:removeSelf()
		is_active = false
		setupTransition()
	end


	-- setup parameters for trajectory motion

	local params = {
		time=1000,
		pBegin=BEGIN_POINT,
		pEnd=END_POINT,
		height=30,
		onComplete=onCompleteCallback
	}
	Trajectory.move( gProjectile, params )

	is_active = true -- set our flag
end



-- setupTouch()
-- create button using text object
-- the button starts the action
--
local function setupTouch()

	local o = display.newText( "Tap Me Here!", 0, 0, native.systemFont, 24 )
	o.anchorX, o.anchorY = 0.5, 0.5
	o.x = 160 ; o.y = 400
	o:setFillColor( 1, 1, 1 )

	local handler = function( e )
		if e.phase == "ended" and is_active == false then
			doTransition()
		end
	end
	o:addEventListener( "touch", handler )

end


-- drawPoints()
-- create and position the points which indicate the begining and ending
-- of the trajectory path
--
local function drawPoints()

	local o

	-- begin point - green
	o = display.newCircle( BEGIN_POINT[1], BEGIN_POINT[2], 3 )
	o:setFillColor( 0, 1, 0 )

	-- end point -- red
	o = display.newCircle( END_POINT[1], END_POINT[2], 3 )
	o:setFillColor( 1, 0, 0 )

end



--== Main Function

local main = function()

	drawPoints()
	setupTouch()

	setupTransition()

end

-- let's get this party started !
--
main()


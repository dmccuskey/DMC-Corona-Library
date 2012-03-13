
--====================================================================--
-- Trajectory Basic
--
-- Shows simple trajectory with a single object.
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2012 David McCuskey. All Rights Reserved.
--====================================================================--
print("---------------------------------------------------")

--=========================================================
-- Imports
--=========================================================

local Trajectory = require( "dmc_trajectory" )


--====================================================================--
-- Setup, Constants
--====================================================================--

display.setStatusBar( display.HiddenStatusBar )

local BEGIN_POINT = { 80, 120 }
local END_POINT = { 240, 240 }

local isActive = false -- is projectile in motion
local projectile

--=========================================================
-- Main
--=========================================================


-- drawPoints()
-- puts begin and dots on the UI
--
function drawPoints()

	local o

	-- begin point - green
	o = display.newCircle( BEGIN_POINT[1], BEGIN_POINT[2], 3 )
	o:setFillColor( 0, 255, 0 )

	-- end point -- red
	o = display.newCircle( END_POINT[1], END_POINT[2], 3 )
	o:setFillColor( 255, 0, 0 )

end


-- setupTouch()
-- create button from text ; controls action
--
function setupTouch()

	local o = display.newText( "Tap Me Here!", 0, 0, native.systemFont, 24 )
	o:setReferencePoint(display.CenterReferencePoint)
	o.x = 160 ; o.y = 400
	o:setTextColor(255, 255, 255)

	local handler = function( e )
		if e.phase == "ended" and isActive == false then doTransition() end
	end
	o:addEventListener( "touch", handler )

end



-- doTransition()
-- recursive function which sets up test points with colored markers and runs a transition
--
function doTransition()

	local complete = function()
		-- clean up test items and start a new round
		projectile:removeSelf()
		isActive = false
		setupTransition()
	end

	local params = {
		time=1000,
		pBegin=BEGIN_POINT,
		pEnd=END_POINT,
		height=30,
		onComplete=complete
	}

	isActive = true
	Trajectory.move( projectile, params )
end


-- setupTransition()
-- create projectile and put on UI at beginning location
--
function setupTransition()

	projectile = display.newCircle( 0, 0, 5 )
	projectile:setFillColor( 0, 0, 255 )
	projectile.x, projectile.y = BEGIN_POINT[1], BEGIN_POINT[2]

end


-- main()
-- let's get this party started !
--
local main = function()

	drawPoints()
	setupTouch()

	setupTransition()

end

main()


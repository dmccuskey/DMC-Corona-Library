--====================================================================--
-- Touch.move() Basic
--
-- Shows simple use of Touch.move()
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2012 David McCuskey. All Rights Reserved.
--====================================================================--
print("---------------------------------------------------")


--===================================================================--
-- Imports
--===================================================================--

local Touch = require( "dmc_touch" )


--===================================================================--
-- Setup, Constants
--===================================================================--

display.setStatusBar( display.HiddenStatusBar )


--===================================================================--
-- Main
--===================================================================--


function handler( event )

	print( event.name .. " : " .. event.phase )
	--print( event.target )
	print( "X:" .. event.moveX .. ", Y: " .. event.moveY )

end


-- main()
-- let's get this party started !
--
local main = function()

	local o

	--== Example One ==--

	o = display.newCircle( 80, 120, 30 )
	o:setFillColor(255,255,255)

	-- free movement
	Touch.move( o )

	-- constrained by x bounds only
	--Touch.move( o, { xBounds = { 120, 200 } } )
	--Touch.move( o, { xBounds = { 120, nil } } )
	--Touch.move( o, { xBounds = { nil, 200 } } )

	-- constrained by y bounds only
	--Touch.move( o, { yBounds = { 200, 280 } } )
	--Touch.move( o, { yBounds = { nil, 280 } } )
	--Touch.move( o, { yBounds = { 200, nil } } )

	o:addEventListener( Touch.MOVE_EVENT, handler )


	--== Example Two ==--

	o = display.newCircle( 160, 240, 30 )
	o:setFillColor(255,100,100)

	-- constrained by x & y bounds
	Touch.move( o, { xBounds = { nil, 200 }, yBounds = { 200, 280 } } )
	--Touch.move( o, { xBounds = { 120, nil }, yBounds = { 200, 280 } } )
	--Touch.move( o, { xBounds = { 120, 200 }, yBounds = { nil, 280 } } )

	-- constrained by angle
	--Touch.move( o, { constrainAngle = 0 } )
	--Touch.move( o, { constrainAngle = 15 } )
	--Touch.move( o, { constrainAngle = 90 } )

	o:addEventListener( Touch.MOVE_EVENT, handler )


	--== Example Three ==--

	o = display.newCircle( 240, 360, 30 )
	o:setFillColor(100,255,100)

	-- constrain angle w x bounds
	--Touch.move( o, { constrainAngle = 0, xBounds = { 120, 200 } } )
	--Touch.move( o, { constrainAngle = 15, xBounds = { 120, 200 } } )
	Touch.move( o, { constrainAngle = -20, xBounds = { 80, 240 } } )
	--Touch.move( o, { constrainAngle = 25, xBounds = { nil, 200 } } )

	-- constrain angle w y bounds
	--Touch.move( o, { constrainAngle = 90, yBounds = { 200, 280 } } )
	--Touch.move( o, { constrainAngle = 75, yBounds = { 200, 280 } } )
	--Touch.move( o, { constrainAngle = 75, yBounds = { nil, 280 } } )

	o:addEventListener( Touch.MOVE_EVENT, handler )

end

main()


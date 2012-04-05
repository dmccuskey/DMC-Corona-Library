--====================================================================--
-- Touch.swipe() Basic
--
-- Shows simple use of Touch.swipe()
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

local feedback = display.newText("", 0, 0, native.systemFont, 48)
feedback:setReferencePoint( display.CenterReferencePoint )
feedback.x = 160 ; feedback.y = 90

local feedback_t, timer_t -- effect handles

function handler( event )

	if event.phase == "ended" then

		feedback.alpha = 1

		if event.direction == nil then
			feedback:setTextColor(255, 0, 0)
			feedback.text = "unregistered"

		else
			feedback:setTextColor(0, 255, 0)
			feedback.text = event.direction
		end

		if timer_t ~= nil then timer.cancel( timer_t ) end
		if feedback_t ~= nil then transition.cancel( feedback_t ) end

		timer_t = timer.performWithDelay( 250, function()

			timer_t = nil
			feedback_t = transition.to( feedback, { time=1000, alpha=0, onComplete=function() feedback_t = nil end })

			end)

	end

end


-- main()
-- let's get this party started !
--
local main = function()

	local o

	--== Example One ==--

	o = display.newRect( 70, 200, 180, 180 )
	o:setFillColor(255,255,255)

	-- free movement
	--Touch.swipe( o )
	--Touch.swipe( o, { limitAngle=-55 } )
	Touch.swipe( o, { useStrictBounds=false } )

	-- constrained by x bounds only
	--Touch.move( o, { xBounds = { 120, 200 } } )
	--Touch.move( o, { xBounds = { 120, nil } } )
	--Touch.move( o, { xBounds = { nil, 200 } } )

	-- constrained by y bounds only
	--Touch.move( o, { yBounds = { 200, 280 } } )
	--Touch.move( o, { yBounds = { nil, 280 } } )
	--Touch.move( o, { yBounds = { 200, nil } } )

	o:addEventListener( Touch.SWIPE_EVENT, handler )


end

main()


--====================================================================--
-- Multitouch.swipe() Basic
--
-- Shows simple use of Touch.swipe()
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2012 David McCuskey. All Rights Reserved.
--====================================================================--
system.activate("multitouch")


print("---------------------------------------------------")


--===================================================================--
-- Imports
--===================================================================--

local MultiTouch = require( "dmc_multitouch" )


-- Tools and Debugging
--[[
--require "CiderDebugger"

--]]

ultimote = require "Ultimote"
ultimote.connect()

--timer.performWithDelay(1000,function() ultimote.screenCapture() end)

--===================================================================--
-- Setup, Constants
--===================================================================--

display.setStatusBar( display.HiddenStatusBar )

--===================================================================--
-- Main
--===================================================================--


local handler = function( event )
	--print( "main handler function", event.phase )
end

local g, o

-- main()
-- let's get this party started !
--
local main = function()


	--== Example One ==--

	g = display.newGroup( )

	o = display.newRect( 0, 0, 500, 500 )
	o:setFillColor(255,255,255)
	o.x = 0 ; o.y = 0
	g:insert( o )

	o = display.newRect( 190, 0, 20, 20 )
	o:setFillColor(255,0,0)
	o.x = 0 ; o.y = -190

	g:insert( o )

	g:setReferencePoint( display.CenterReferencePoint )
	g.x = 384 ; g.y = 512
	g.rotation = 0 ---15

	--g:toBack()

	MultiTouch.bless( g, {

		doRotate = false,
		doPinch = false,
		doMove = false,

		pinch = { max_scale=2, min_scale=0.5, max_width=100, min_width=40, doElastic=true }
	})

	--g:addEventListener( MultiTouch.MULTITOUCH_EVENT, handler )

end

main()




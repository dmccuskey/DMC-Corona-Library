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

print("---------------------------------------------------")


--===================================================================--
-- Imports
--===================================================================--

local MultiTouch = require( "dmc_multitouch" )


-- Tools and Debugging
--[[
local isSimulator = "simulator" == system.getInfo("environment")
if isSimulator then
	ultimote = require "Ultimote"
	ultimote.connect()
end
--]]


--===================================================================--
-- Setup, Constants
--===================================================================--

system.activate("multitouch")
display.setStatusBar( display.HiddenStatusBar )

--===================================================================--
-- Main
--===================================================================--


local handler = function( event )
	--print( "main handler function", event.phase )
end



function setup_object_one()

	local g, o

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
	g.x = 384 ; g.y = 712
	g.rotation = 0 ---15

	g:toBack()

	return g

end


function setup_object_two()

	local g, o

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
	g.x = 384 ; g.y = 312
	g.rotation = 0 ---15

	g:toBack()

	return g

end




-- main()
-- let's get this party started !
--
local main = function()

	local o

	o = setup_object_one()


	MultiTouch.bless( o, {

		doRotate = true,
		doPinch = true,
		doMove = true,

		pinch = { max_scale=2, min_scale=0.5, max_width=100, min_width=40, doElastic=true }
	})



	o = setup_object_two()


	MultiTouch.bless( o, {

		doRotate = true,
		doPinch = true,
		doMove = true,

		pinch = { max_scale=2, min_scale=0.5, max_width=100, min_width=40, doElastic=true }
	})

end

main()




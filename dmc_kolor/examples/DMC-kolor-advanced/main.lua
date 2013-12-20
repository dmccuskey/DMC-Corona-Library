--====================================================================--
-- Kolor Advanced
--
-- Shows that other libraries can create and use HDR display objects
-- mixed in with dmc_kolor
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.
--====================================================================--

print("---------------------------------------------------")

--===================================================================--
-- Imports
--===================================================================--

-- just need to require the module
local display = require( 'dmc_kolor' )
local UFOFactory = require( "ufo" )

local rand = math.random


--===================================================================--
-- Setup, Constants
--===================================================================--



--====================================================================--
-- Main
--====================================================================--

local ufo = UFOFactory.create()
ufo.x, ufo.y = rand(10, 300), rand(10, 470)

ufo._circle:setFillRGB( 255, 255, 0 )

ufo._circle:setFillColor( .5, .5, .5 )


local newCircle1 = display.newCircle( 150, 375, 30 )
newCircle1:setFillColor( "Chartreuse" )
newCircle1.strokeWidth = 5
newCircle1:setStrokeColor( 150, 150, 150 )


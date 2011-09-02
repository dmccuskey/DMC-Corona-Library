--====================================================================--
-- UFO
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--


--====================================================================--
-- Imports
--====================================================================--

local UFOFactory = require( "ufo" )


--====================================================================--
-- Setup, Constants
--====================================================================--

local seed = os.time();
math.randomseed( seed )
local rand = math.random

display.setStatusBar( display.HiddenStatusBar )


-- setup our space background
local BG = display.newImageRect( "assets/space_bg.png", 320, 480 )
BG.x, BG.y = 160, 240



--====================================================================--
-- Create UFOs
--====================================================================--

local ufo = UFOFactory.create()
ufo.x, ufo.y = rand(10, 300), rand(10, 470)

local ufo2 = UFOFactory.create()
ufo2.x, ufo2.y = rand(10, 300), rand(10, 470)


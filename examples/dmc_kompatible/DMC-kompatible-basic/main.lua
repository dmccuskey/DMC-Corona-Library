--====================================================================--
-- Kompatible Basic
--
-- Tests the Kompatible library
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

local display, native = _G.display, _G.native


--===================================================================--
-- Setup, Constants
--===================================================================--

local one, two = string.match( system.getInfo('build'), '(%d+)%.(%d+)')
if tonumber( two ) > 2000 then
	print( "importing dmc_kompatible" )
	display, native = require( 'dmc_kompatible' )()
end

local drawLine


--===================================================================--
-- Kompatible Support
--===================================================================--


drawLine = function( x1,y1,x2,y2 )
	line = display.newLine( x1, y1, x2, y2 )
	line.width = 1
	line:setColor( 255, 0, 0 )
end


---== Draw Grid

local x1, x2, y1, y2, x, y
local o, line
local radius, width, height

-- vertical
y1, y2 = 100, 1000
x=101
drawLine( x, y1, x, y2 )
x=225
drawLine( x, y1, x, y2 )
x=351
drawLine( x, y1, x, y2 )
x=475
drawLine( x, y1, x, y2 )

-- horizontal
x1, x2 = 50, 600
y=151
drawLine( x1, y, x2, y )
y=301
drawLine( x1, y, x2, y )
y=451
drawLine( x1, y, x2, y )
y=601
drawLine( x1, y, x2, y )
y=750
drawLine( x1, y, x2, y )




--== Test Circle (default: center)

radius = 30
y = 151
o = display.newCircle( 0, 0, radius )
o.x, o.y = 101, y
o:setFillColor( 150 )
o.strokeWidth = 5

o = display.newCircle( 0, 0, radius )
o:setReferencePoint( display.TopLeftReferencePoint )
o.x, o.y = 225-radius, y-radius
o:setFillColor( 150, 150, 150 )
o.strokeWidth = 5

o = display.newCircle( 0, 0, radius )
o:setReferencePoint( display.CenterReferencePoint )
o.x, o.y = 351, y
o:setFillColor( 100, 150 )
o.strokeWidth = 5

o = display.newCircle( 0, 0, radius )
o:setReferencePoint( display.BottomRightReferencePoint )
o.x, o.y = 475+radius, y+radius
o:setFillColor( 100, 100, 100, 150 )
o.strokeWidth = 5


--== Test Rect (default: center)

width, height = 100, 100
w, h = width/2, height/2
y = 301
o = display.newRect( 0, 0, width, height )
o.x, o.y = 101, y
o:setFillColor( 150 )
o.strokeWidth = 10
o:setStrokeColor( 200 )

o = display.newRect( 0, 0, width, height )
o:setReferencePoint( display.TopLeftReferencePoint )
o.x, o.y = 225-w, y-h
o:setFillColor( 150, 150, 150 )
o.strokeWidth = 10
o:setStrokeColor( 200, 200, 200 )

o = display.newRect( 0, 0, width, height )
o:setReferencePoint( display.CenterReferencePoint )
o.x, o.y = 351, y
o:setFillColor( 150, 150 )
o.strokeWidth = 10
o:setStrokeColor( 200, 150 )

o = display.newRect( 0, 0, width, height )
o:setReferencePoint( display.BottomRightReferencePoint )
o.x, o.y = 475+w, y+h
o:setFillColor( 150, 150, 150, 150 )
o.strokeWidth = 10
o:setStrokeColor( 200, 200, 200, 150 )




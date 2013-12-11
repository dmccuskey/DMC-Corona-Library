--====================================================================--
-- Kolor Basic
--
-- Shows simple use of the Kolor library
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
require( 'dmc_kolor' )



--===================================================================--
-- Setup, Constants
--===================================================================--



--===================================================================--
-- Kolor Support
--===================================================================--


--== Test Polygon

local vertices = { 0,-110, 27,-35, 105,-35, 43,16, 65,90, 0,45, -65,90, -43,15, -105,-35, -27,-35, }
local newPoly1 = display.newPolygon( 150, 200, vertices )
newPoly1.strokeWidth = 10
newPoly1:setStrokeColor( "Dark Magenta" )
newPoly1:setFillColor( 255, 255, 0 )

local newPoly2 = display.newPolygon( 325, 200, vertices )
newPoly2.strokeWidth = 10
newPoly2:setStrokeRGB( "Dark Magenta" )
newPoly2:setFillRGB( 255, 255, 0 )

local newPoly3 = display.newPolygon( 500, 200, vertices )
newPoly3.strokeWidth = 10
newPoly3:setStrokeHDR( .55, 0, .55 )
newPoly3:setFillHDR( 1, 1, 0 )


--== Test Circle

local newCircle1 = display.newCircle( 150, 375, 30 )
newCircle1:setFillColor( "Chartreuse" )
newCircle1.strokeWidth = 5
newCircle1:setStrokeColor( 150, 150, 150 )

local newCircle2 = display.newCircle( 325, 375, 30 )
newCircle2:setFillRGB( "Chartreuse" )
newCircle2.strokeWidth = 5
newCircle2:setStrokeRGB( 150, 150, 150 )

local newCircle3 = display.newCircle( 500, 375, 30 )
newCircle3:setFillHDR( .5, 1, 0 )
newCircle3.strokeWidth = 5
newCircle3:setStrokeHDR( .5, .5, .5 )


--== Test Rect

local rect1 = display.newRect( 200, 700, 100, 200 )
rect1:setFillColor( "Misty Rose" )
rect1.strokeWidth = 5
rect1:setStrokeColor( 180, 50, 100 )

-- even RGB gradients get translated !!

local gradient = {
    type="gradient",
    color1={ 255, 255, 255 }, color2={ 150, 150, 150 }, direction="down"
}
local rect2 = display.newRect( 400, 700, 100, 200 )
rect2:setFillColor( gradient )
rect2.strokeWidth = 5
rect2:setStrokeColor( 150, 150, 150 )


--== Test Text

local myText1 = display.newText( "hello there", 150, 475, native.systemFontBold, 20 )
myText1:setFillColor( "Turquoise" )

local myText2 = display.newText( "hello there", 325, 475, native.systemFontBold, 20 )
myText2:setFillColor( 64, 224, 208 )

local myText3 = display.newText( "hello there", 500, 475, native.systemFontBold, 20 )
myText3:setFillHDR( .25, .88, .82 )


--== Test Line

local x1, x2, y1, y2

x1, x2, y1, y2 = 125, 175, 900, 950

local star1 = display.newLine( x1,y1, x2,y1 )
star1:append( x2,y2, x1,y2, x1,y1 )
star1.strokeWidth = 15
star1:setStrokeColor( 150, 150, 150 )  -- << bug here, use setStrokeRGB

x1, x2, y1, y2 = 275, 325, 900, 950

local star2 = display.newLine( x1,y1, x2,y1 )
star2:append( x2,y2, x1,y2, x1,y1 )
star2.strokeWidth = 15
star2:setStrokeRGB( 150, 150, 150 )  -- << bug here, use setStrokeRGB



--[[
--== Test Text Box

local textBox1 = native.newTextBox( 30, 140, 260, 150 )
textBox1:setTextColor( 200, 250, 250, 255 )

local textBox2 = native.newTextBox( 30, 140, 260, 150 )
textBox2:setTextColor( 200, 250, 250, 255 )


--== Test Text Field

local field1 = native.newTextField( 250, 100, 100, 35 )
field1.text = "hello there my friend"
field1:setTextColor( 255, 0, 150 )

local field2 = native.newTextField( 50, 100, 100, 35 )
field2.text = "hello there my friend"
field2:setTextColor( 0, 150, 255 )
--]]




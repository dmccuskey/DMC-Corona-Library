--====================================================================--
-- Multi-shapes
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

local ButtonFactory = require( "dmc_buttons" )
local PushButton = ButtonFactory.PushButton

local ShapeFactory
ShapeFactory = require( "shapes" )
--ShapeFactory = require( "shapes2" )


--====================================================================--
-- Setup, Constants
--====================================================================--

local seed = os.time();
math.randomseed( seed )

local rand = math.random
local CONTENT_W = display.viewableContentWidth
local CONTENT_H = display.viewableContentHeight
local NUM_SHAPES = 10

display.setStatusBar( display.HiddenStatusBar )



--====================================================================--
-- Create Shapes
--====================================================================--

local shapeList = {}
-- create this group to maintain layering of shapes/button
local shapeGroup = display.newGroup()


local function clearShapes()

	for i=table.getn( shapeList ), 1, -1 do
		local shape = table.remove( shapeList, i )
		shape:destroy()
	end

end

local function drawShapes()

	for i=1, NUM_SHAPES do
		local shape = ShapeFactory.create()
		table.insert( shapeList, shape )
		shapeGroup:insert( shape.display )
		local x, y, rotate = rand( CONTENT_W ), rand( CONTENT_H )
		shape.x = x ; shape.y = y
	end

end


-- The Push Button

local function buttonChangeHandler( event )
	if event.phase == PushButton.PHASE_RELEASE then
		clearShapes()
		drawShapes()
	end

	return true
end

local pushBtnParams = {
	label="Randomize",
	style= { size=20, yOffset=-4 },
	width=152,
	height=56,
	defaultSrc="assets/btn_bg_green_128x32.png",
	downSrc="assets/btn_bg_orange_down_128x32.png",
}

local pushBtn = ButtonFactory.create( "push", pushBtnParams )
pushBtn.x = 160 ; pushBtn.y = 440
pushBtn:addEventListener( "touch", buttonChangeHandler )


-- Start the initial Draw

clearShapes()
drawShapes()


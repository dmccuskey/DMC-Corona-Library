--====================================================================--
-- Drag n Drop OOP
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--
print("---------------------------------------------------")

--=========================================================
-- Imports
--=========================================================

local DragMgr = require ( "dmc_dragdrop" )
local Utils = require( "dmc_utils" )


-- object-oriented Drop Target implementation
local DropTarget = require ( "drop_target" )



--====================================================================--
-- Setup, Constants
--====================================================================--

local color_blue = { 25, 100, 255 }
local color_lightblue = { 90, 170, 255 }
local color_green = { 50, 255, 50 }
local color_lightgreen = { 170, 225, 170 }
local color_red = { 255, 50, 50 }
local color_lightred = { 255, 120, 120 }
local color_grey = { 180, 180, 180 }
local color_lightgrey = { 200, 200, 200 }

display.setStatusBar( display.HiddenStatusBar )



--=========================================================
-- Main
--=========================================================


-- background

local localGroup = display.newGroup()

local background = display.newImageRect( "assets/bg_screen_generic.png", 320, 480 )
background:setReferencePoint( display.TopLeftReferencePoint )
background.x = 0 ; background.y = 0
localGroup:insert( background )



--== Support Items ==--

-- createSquare()
--
-- function to help create shapes, useful for drag/drop target examples
--
local function createSquare( size, color )

	s = display.newRect(0, 0, unpack( size ) )
	s.strokeWidth = 3
	s:setFillColor( unpack( color ) )
	s:setStrokeColor( unpack( color_grey ) )

	return s
end





--==============================================================
-- Setup DROP Targets - areas we drag TO
--==============================================================



--== Setup Drop Targets, using object-oriented code ==--
-- For details, see the file 'drop_target.lua'

-- this one, Blue, accepts only Blue drag notifications
local dropTarget2 = DropTarget.create( { format={ "blue" }, color=color_lightblue } )
dropTarget2.x = 80 ; dropTarget2.y =  240

DragMgr:register( dropTarget2 )


-- this one, Grey, accepts both Blue and Red drag notifications
local dropTarget3 = DropTarget.create( { format={ "blue", "red" } } )
dropTarget3.x = 160 ; dropTarget3.y =  110

DragMgr:register( dropTarget3 )


-- this one, Light Red, accepts only Red drag notifications
local dropTarget4 = DropTarget.create( { format="red", color=color_lightred } )
dropTarget4.x = 240 ; dropTarget4.y =  240

DragMgr:register( dropTarget4 )






--==============================================================
-- Setup DRAG Targets - areas we drag FROM
--==============================================================


y_base = 400

--== create Red Drag Target ==--

local function dragItemTouchHandler( event )

	if event.phase == "began" then

		local target = event.target

		-- setup info about the drag operation
		local drag_info = {
			proxy = createSquare( { 75, 75 }, color_lightred ),
			format = "red",
			yOffset = -30,
		}

		-- now tell the Drag Manager about it
		DragMgr:doDrag( target, event, drag_info )
	end

	return true
end

-- this is the drag target, the location from which we start a drag
local dragItem = createSquare( { 75, 75 }, color_lightred )
dragItem.x = 80 ; dragItem.y = y_base

dragItem:addEventListener( "touch", dragItemTouchHandler )



--== create Blue Drag Target ==--

local function dragItemTouchHandler2( event )

	if event.phase == "began" then

		local target = event.target

		-- setup info about the drag operation
		local drag_info = {
			proxy = createSquare( { 75, 75 }, color_lightblue ),
			format = "blue",
			yOffset = -30,
		}

		-- now tell the Drag Manager about it
		DragMgr:doDrag( target, event, drag_info )
	end

	return true
end

-- this is the drag target, the location from which we start a drag
local dragItem2 = createSquare( { 75, 75 }, color_lightblue )
dragItem2.x = 240 ; dragItem2.y = y_base

dragItem2:addEventListener( "touch", dragItemTouchHandler2 )








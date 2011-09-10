--====================================================================--
-- Drag n Drop Basic
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--


--=========================================================
-- Imports
--=========================================================

local DragMgr = require ( "dmc_dragdrop" )
local Utils = require( "dmc_utils" )


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

local localGroup = display.newGroup()


-- background

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
-- Setup DROP Target - areas we drag TO
--==============================================================


local theScore =  0
local textScore, updateScore

local dragStartHandler = function( e )

	local o = e.target
	o:setStrokeColor( unpack( color_red ) )

	return true
end
local dragEnterHandler = function( e )

	local o = e.target
	o:setFillColor( unpack( color_lightgreen ) )

	DragMgr:acceptDragDrop()

	return true
end
local dragOverHandler = function( e )

	return true
end

-- have to declare dragExitHandler ahead
-- since dragDropHandler calls it
--
local dragExitHandler

local dragDropHandler = function( e )

	theScore = theScore + 1
	updateScore()
	dragExitHandler( e )

	return true
end
dragExitHandler = function( e )

	local o = e.target
	o:setFillColor( unpack( color_lightblue ) )

	return true
end
local dragStopHandler = function( e )

	local o = e.target
	o:setStrokeColor( unpack( color_grey ) )

	return true
end


local dropTarget = createSquare( { 125, 125 }, color_lightblue )
dropTarget.x = 160 ; dropTarget.y = 200

DragMgr:register( dropTarget, {
	dragStart=dragStartHandler,
	dragEnter=dragEnterHandler,
	dragOver=dragOverHandler,
	dragDrop=dragDropHandler,
	dragExit=dragExitHandler,
	dragStop=dragStopHandler,
})

updateScore = function()
	local txt = tostring( theScore )
	textScore.text = txt
	textScore.x = 160 ; textScore.y = 200
end

textScore = display.newText( "", 160, 160, native.systemFont, 24 )
textScore:setTextColor( 0, 0, 0, 255 )
textScore:setReferencePoint( display.CenterReferencePoint )

updateScore()



--==============================================================
-- Setup DRAG Target - areas we drag FROM
--==============================================================


local function dragItemTouchHandler( event )

	if event.phase == "began" then

		-- setup info about the Drag Operation
		local drag_info = {
			origin = event.target,
		}

		-- now tell the Drag Manager about it
		DragMgr:doDrag( drag_info, event )
	end

	return true
end

-- this is the Drag Initiator
-- ie, the location from which we start a drag
--
local dragItem = createSquare( { 75, 75 }, color_lightblue )
dragItem.x = 160 ; dragItem.y = 400

dragItem:addEventListener( "touch", dragItemTouchHandler )








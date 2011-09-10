--====================================================================--
-- Drag n Drop Basic
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



--== Setup two Drop Targets, using object-oriented code ==--
-- For details, see the file 'drop_target.lua'

-- this one, Grey, accepts both Blue and Red drag notifications
local dropTarget3 = DropTarget.create( { format={ "blue", "red" } } )
dropTarget3.x = 160 ; dropTarget3.y =  110

DragMgr:register( dropTarget3 )


-- this one, Light Red, accepts only Red drag notifications
local dropTarget4 = DropTarget.create( { format="red", color=color_lightred } )
dropTarget4.x = 240 ; dropTarget4.y =  240

DragMgr:register( dropTarget4 )





--== Create another Drop Target, this one not OO ==--

-- ===============================
-- START Non-OO Drop Target

local theScore1 =  0
local textScore1, updateScore1

local dragStartHandler = function( e )
	--print("in dragStartHandler")
	-- accept here or...
	local o = e.source
	local data_format = e.format
	if Utils.propertyIn( { "blue" }, data_format ) then
		o:setStrokeColor( unpack( color_red ) )
	end


	return true
end
local dragEnterHandler = function( e )
	--print("in dragEnterHandler")
	local o = e.source
	local data_format = e.format

	if Utils.propertyIn( { "blue" }, data_format ) then
		--print("--Drag Accepted")
		o:setFillColor( unpack( color_lightgreen ) )
		DragMgr:acceptDragDrop()
	end

	return true
end
local dragOverHandler = function( e )
	--print("in dragOverHandler")

	return true
end

-- have to declare this one ahead
-- since dragDropHandler calls it
--
local dragExitHandler

local dragDropHandler = function( e )
	--print("in dragDropHandler")
	theScore1 = theScore1 + 1
	updateScore1()
	dragExitHandler( e )

	return true
end
dragExitHandler = function( e )
	--print("in dragExitHandler")
	local o = e.source
	local data_format = e.format
	o:setFillColor( unpack( color_lightblue ) )

	return true
end
local dragStopHandler = function( e )
	--print("in dragStopHandler")
	local o = e.source
	o:setStrokeColor( unpack( color_grey ) )

	return true
end


local dropTarget = createSquare( { 125, 125 }, color_lightblue )
dropTarget.x = 80
dropTarget.y = 240

DragMgr:register( dropTarget, {
	dragStart=dragStartHandler,
	dragEnter=dragEnterHandler,
	dragOver=dragOverHandler,
	dragDrop=dragDropHandler,
	dragExit=dragExitHandler,
	dragStop=dragStopHandler,
})

local myy_base = 240
updateScore1 = function()
	local txt = tostring( theScore1 )
	textScore1.text = txt
	textScore1.x = 80
	textScore1.y = myy_base
end

textScore1 = display.newText( "", 160, 160, native.systemFont, 24 )
textScore1:setTextColor( 0, 0, 0, 255 )
textScore1:setReferencePoint( display.CenterReferencePoint )

updateScore1()


-- END Non-OO Drop Target
-- ===============================




--==============================================================
-- Setup DRAG Targets - areas we drag FROM
--==============================================================


y_base = 400

--== create Red Drag Target ==--

local function dragItemTouchHandler( e )

	if e.phase == "began" then

		-- setup the item that is going to be dragged around the screen
		local drag_source = e.target
		local drag_info = {}
		drag_info.target = createSquare( { 75, 75 }, color_lightred )

		-- move location from our finger, so we can see it
		drag_info.yOffset = -30

		-- now tell the Drag Manager about it
		DragMgr:doDrag( drag_source, "red", e, drag_info )
	end

	return true
end

-- this is the drag target, the location from which we start a drag
local dragItem = createSquare( { 75, 75 }, color_lightred )
dragItem.x = 80 ; dragItem.y = y_base

dragItem:addEventListener( "touch", dragItemTouchHandler )



--== create Blue Drag Target ==--

local function dragItemTouchHandler2( event )

	if e.phase == "began" then

		-- setup the item that is going to be dragged around the screen
		local drag_source = event.target
		local drag_info = {}
		drag_info.target = createSquare( { 75, 75 }, color_lightblue )

		-- move location from our finger, so we can see it
		drag_info.yOffset = -30

		-- now tell the Drag Manager about it
		DragMgr:doDrag( drag_source, "blue", event, drag_info )
	end

	return true
end

-- this is the drag target, the location from which we start a drag
local dragItem2 = createSquare( { 75, 75 }, color_lightblue )
dragItem2.x = 240 ; dragItem2.y = y_base

dragItem2:addEventListener( "touch", dragItemTouchHandler2 )








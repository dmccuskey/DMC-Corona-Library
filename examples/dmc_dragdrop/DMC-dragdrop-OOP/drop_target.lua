--====================================================================--
-- OO Drop Target
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--


-- =========================================================
-- Imports
-- =========================================================

local Objects = require( "dmc_objects" )
local Utils = require( "dmc_utils" )
local DragMgr = require ( "dmc_dragdrop" )

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase


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



-- =========================================================
-- Drop Target Class
-- =========================================================

local DropTarget = inheritsFrom( CoronaBase )
DropTarget.NAME = "Drop Target"


-- _init()
--
-- initialize our object
-- base dmc_object override
--
function DropTarget:_init( options )

	self:superCall( "_init" )

	self.score = 0
	self.format = {}
	self.color = nil	-- { 255, 25, 255 }
	self.background = nil
	self.scoreboard = nil

	if options.format then
		if type( options.format ) == "string" then
			self.format = { options.format }

		elseif type( options.format ) == "table" then
			self.format = options.format
		end
	end

	self.color  = ( options.color ) and options.color or color_lightgrey

end


-- _createView()
--
-- create our object's view
-- base dmc_object override
--
function DropTarget:_createView()

	local background = createSquare( { 120, 120 }, self.color )
	background:setReferencePoint( display.CenterReferencePoint )
	background.x = 0 ; background.y = 0
	self:insert( background )

	self.background = background

	local scoreboard = display.newText( "", 0, 0, native.systemFont, 24 )
	scoreboard:setTextColor( 0, 0, 0, 255 )
	scoreboard:setReferencePoint( display.CenterReferencePoint )
	scoreboard.x = 0 ; scoreboard.y = 0
	self:insert( scoreboard )

	self.scoreboard = scoreboard

end


-- _initComplete()
--
-- post init actions
-- base dmc_object override
--
function DropTarget:_initComplete()
	-- draw initial score
	self:_updateScore()
end



-- define method handlers for each drag phase

function DropTarget:dragStart( e )

	local data_format = e.format
	if Utils.propertyIn( self.format, data_format ) then
		self.background:setStrokeColor( 255, 0, 0 )
	end

	return true
end
function DropTarget:dragEnter( e )
	-- must accept drag here

	local data_format = e.format
	if Utils.propertyIn( self.format, data_format ) then
		self.background:setFillColor( unpack( color_lightgreen ) )
		DragMgr:acceptDragDrop()
	end

	return true
end
function DropTarget:dragOver( e )

	return true
	end
function DropTarget:dragDrop( e )

	self:_incrementScore()
	self:dragExit( e )

	return true
end
function DropTarget:dragExit( e )

	self.background:setFillColor( unpack( self.color ) )

	return true
end
function DropTarget:dragStop( e )

	self.background:setStrokeColor( unpack( color_grey ) )

	return true
end

function DropTarget:_incrementScore()
	self.score = self.score + 1
	self:_updateScore()
end

function DropTarget:_updateScore()
	self.scoreboard.text = tostring( self.score )
	self.scoreboard.x = 0 ; self.scoreboard.y = 0
end



-- The Factory

local DropTargetFactory = {}

function DropTargetFactory.create( options )
	return DropTarget:new( options )
end


return DropTargetFactory





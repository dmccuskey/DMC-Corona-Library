--====================================================================--
-- UFO2
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2011 David McCuskey. All Rights Reserved.
--====================================================================--

print("------------------------------------------------")


--====================================================================--
-- Imports
--====================================================================--

local widget = require( "widget" )
local UFOFactory = require( "ufo" )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- hide status bar
if system.getInfo("environment") ~= 'simulator' then
	display.setStatusBar( display.HiddenStatusBar )
end

local seed = os.time();
math.randomseed( seed )
local rand = math.random

local MAX_UFOS = 5

-- display groups, this order
local bg_group
local ufo_group
local ui_group

local ufo_dict

local handleUFOTouchedEvent -- forward declare function



--====================================================================--
-- Main
--====================================================================--


--== Support functions


local function createUFO()

	local ufo, key

	-- object
	ufo = UFOFactory:new()
	ufo_group:insert( ufo.view )

	-- event listener
	ufo:addEventListener( ufo.EVENT, handleUFOTouchedEvent )

	-- storage
	key = tostring( ufo )
	ufo_dict[ key ] = ufo

end

local function deleteUFO( ufo )

	local key

	-- storage
	key = tostring( ufo )
	ufo_dict[ key ] = nil

	-- event listener
	ufo:removeEventListener( ufo.EVENT, handleUFOTouchedEvent )

	-- object
	ufo:removeSelf()

end




--== Event Handlers


handleUFOTouchedEvent = function( event )
	deleteUFO( event.target )
end


local function handleCreateButtonEvent( event )
	if "ended" == event.phase then
		createUFO()
	end
	return true
end

local function handleMoveButtonEvent( event )
	if "ended" == event.phase then
		local speeds = { UFOFactory.FAST, UFOFactory.MEDIUM, UFOFactory.SLOW }

		-- loop through all ufo objects,
		-- get random speed and ask ufo to move()
		-- with that speed
		for k, ufo in pairs( ufo_dict ) do 
			local idx = math.random(#speeds)
			ufo:move( speeds[ idx ] )
ufo.xScale, ufo.yScale=0.5, 0.5
ufo.xScale, ufo.yScale=0.5, 0.5
ufo.xScale, ufo.yScale=1.0, 1.0
ufo.xScale, ufo.yScale=40.0, 40.0
ufo.xScale, ufo.yScale=1.0, 1.0
		end
	end
	return true
end




--== Setup App Layers


local function setupBackgroundLayer()

	bg_group = display.newGroup()

	-- create space background
	local o = display.newImageRect( "assets/space_bg.png", display.viewableContentWidth, display.viewableContentHeight )
	o.x, o.y = display.viewableContentWidth/2, display.viewableContentHeight/2

	bg_group:insert( o )

end


local function setupUFOLayer()

	ufo_group = display.newGroup()

end


local function setupUILayer()

	local H_CENTER = display.viewableContentWidth/2
	local PADDING = 15

	-- button constants
	local w, h = 120, 45
	local y = display.viewableContentHeight-h-PADDING

	local o 


	ui_group = display.newGroup()


	-- move button
	o = widget.newButton
	{
		left = H_CENTER-w-PADDING,
		top = y,
		width = w,
		height = h,
		label = "Create",
		onEvent = handleCreateButtonEvent,
	}
	ui_group:insert( o )

	-- create button
	o = widget.newButton
	{
		left = H_CENTER+PADDING,
		top = y,
		width = w,
		height = h,
		label = "Move",
		onEvent = handleMoveButtonEvent,
	}
	ui_group:insert( o )

end




local function main()

	ufo_dict = {}

	-- in this order to properly layer display groups
	setupBackgroundLayer()
	setupUFOLayer()
	setupUILayer()

end


main()





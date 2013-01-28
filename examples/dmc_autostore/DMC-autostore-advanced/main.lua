--====================================================================--
-- AutoStore Advanced
--
-- Shows simple use of the AutoStore library
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2013 David McCuskey. All Rights Reserved.
--====================================================================--

print("---------------------------------------------------")


--===================================================================--
-- Imports
--===================================================================--

local AutoStore = require( "dmc_autostore" )
local UFOFactory = require( "ufo" )
local ProgressBar = require( "progress_bar" )



--===================================================================--
-- Setup, Constants
--===================================================================--

display.setStatusBar( display.HiddenStatusBar )


local min_bar, max_bar, saved_text

--===================================================================--
-- AutoStore Support
--===================================================================--

--[[
our complete app structure is going to look like so:

{
	ufos = {
		{ x=22, y=55, temp='cool' },
		{ x=30, y=100, temp='hot' },
		...
	}

}
--]]

-- initializeAutoStore()
--
-- check if a we have a new file (first app launch)
-- initialize data structure
-- 
local function initializeAutoStore()
	--print( "initializeAutoStore" )

	if not AutoStore.is_new_file then return end

	--== new data file, setup the base storage structure ==--

	local data = AutoStore.data

	-- create container for for the objects
	data[ 'ufos' ] = {}

	-- to start with something, let's put in a single UFO
	local ufo = { x=240, y=160, temperature='cool' }

	createNewUFO( ufo )
end


-- createExistingUFOs()
--
-- app start, get our stored data and create any UFOs
--
local function createExistingUFOs()
	--print( "createExistingUFOs" )

	local ufos = AutoStore.data.ufos -- get small branch of storage tree
	local o -- ufo object ref

	-- loop through 'ufos' container and create objects
	for id, data in ufos:pairs() do

		-- data is a reference to a "magic" part of the storage tree
		-- the object will keep a reference to it and
		-- read or update values with it
		o = UFOFactory.create( id, data )
	end

end


-- data is table, { x, y }
local function createNewUFO( data )
	--print( "createNewUFO" )

	data.temperature = 'cool'

	local ufos, magic, o

	local id = system.getTimer()

	-- save our new UFO data first, retrieve magic branch
	ufos = AutoStore.data.ufos -- get small branch of storage tree
	ufos[ id ] = data

	-- create our new UFO, get magic data data
	o = UFOFactory.create( id, ufos[ id ] )

end



--===================================================================--
-- Main
--===================================================================--


local function doDataSavedDisplay()
	--print( "doDataSavedDisplay" )

		saved_text.xScale=1 ; saved_text.yScale=1
		saved_text.alpha = 1
		transition.to( saved_text, { xScale=2, yScale=2, alpha=0, time=750 } )

end

local function autostoreEventHandler( event )
	--print( 'autostoreEventHandler' )

	if event.type == AutoStore.DATA_SAVED then
		doDataSavedDisplay()

	elseif event.type == AutoStore.START_MIN_TIMER then
		min_bar:start( event.time )

	elseif event.type == AutoStore.STOP_MIN_TIMER then
		min_bar:stop()

	elseif event.type == AutoStore.START_MAX_TIMER then
		max_bar:start( event.time )

	elseif event.type == AutoStore.STOP_MAX_TIMER then
		max_bar:stop()
	end

end

local function backgroundTouchHandler( e )
	--print( "backgroundTouchHandler" )

	local y, data

	if e.phase == 'ended' then
		y = e.y
		data = {
			x=e.x,
			y=e.y,
		}

		createNewUFO( data )
	end

	return true
end


-- initializeApp()
--
-- 
local function initializeApp()
	--print( "initializeApp" )

	local o

	o = display.newImageRect( "assets/space_bg.png", 480, 320 )
	o.x = 240 ; o.y = 160

	o:addEventListener( "touch", backgroundTouchHandler )

	-- MIN label & progress bar 
	o = display.newText( "Min", 15, -2, nil, 14 )

	o = ProgressBar.create( { x=60, y=10, width=400, height=8, color='orange' } )
	min_bar = o

	-- MAX label & progress bar
	o = display.newText( "Max", 15, 17, nil, 14 )

	o = ProgressBar.create( { x=60, y=30, width=400, height=8, color='red' } )
	max_bar = o

	-- "Data Saved" display
	o = display.newText( "Data Saved !!", 160, 100, native.systemFontBold, 24 )
	o:setTextColor(255, 0, 0)
	o.alpha = 0
	saved_text = o

	AutoStore:addEventListener( AutoStore.AUTOSTORE_EVENT, autostoreEventHandler )

end



-- main()
--
local main = function()

	initializeApp()

	initializeAutoStore()

	createExistingUFOs()

end


-- let's get this party started !
--
main()




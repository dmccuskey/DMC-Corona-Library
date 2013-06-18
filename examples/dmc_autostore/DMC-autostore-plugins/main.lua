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

if system.getInfo("environment") ~= 'simulator' then
	display.setStatusBar( display.HiddenStatusBar )
end


local min_bar, max_bar, saved_text
local dg_bg, dg_ufo, dg_fg



--===================================================================--
-- AutoStore Support
--===================================================================--

--[[

Anything in this area has something to do with AutoStore.
You'll find examples to initialize a new, empty AutoStore data structure,
or adding new items, or looping through existing data

--]]


-- createNewUFO
--
-- create a new UFO object based on the data parameter
-- @param data table: coordinates for UFO location, eg { x=33, y=209 }
local function createNewUFO( data )
	--print( "createNewUFO" )

	data.temperature = 'cool'

	local id = system.getTimer() -- key for our new UFO
	local ufos, magic, o


	--== AutoStore functionality ==--
	-- save our new UFO data first
	-- then retrieve "magic" branch AFTER
	--
	ufos = AutoStore.data.ufos -- get small branch of storage tree
	ufos[ id ] = data  -- add in our new data
	data = ufos[ id ]  -- retrieve the "magic" data branch


	-- now create our new UFO object, passing in our "magic" data branch
	o = UFOFactory.create( id, data )
	dg_ufo:insert( o._dg )

end



-- createExistingUFOs()
--
-- app start, get our stored data and create any UFOs
--
local function createExistingUFOs()
	--print( "createExistingUFOs" )

	local ufos
	local o -- ufo object ref


	--== AutoStore functionality ==--
	-- get the UFO branch from the data tree
	-- loop through 'ufos' container and create objects
	-- Note: we're calling pairs() as a method ON our branch
	--
	ufos = AutoStore.data.ufos -- get small branch of storage tree
	for id, data in ufos:pairs() do

		-- data is a reference to a "magic" part of the storage tree
		-- we are passing THAT into the object
		-- the object will keep a reference to it and use this ref
		-- to read or update its values
		--
		o = UFOFactory.create( id, data )
		dg_ufo:insert( o._dg )
	end

end



--[[
our complete data structure is going to look like so:

{
	ufos = {
		{ x=22, y=55, temperature='cool' },
		{ x=30, y=100, temperature='hot' },
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


	--== new data file, initialize the data structure ==--

	-- get a reference to the root of the data structure
	-- right now 'data' is an empty, "magic" table, eg {}
	local data = AutoStore.data

	-- add empty container to the tree in which to store our UFO objects
	data[ 'ufos' ] = {}

	-- to start with something, let's put in a single UFO
	local ufo = { x=240, y=160, temperature='cool' }
	createNewUFO( ufo )

end



--===================================================================--
-- Main
--===================================================================--


--[[

Anything below here doesn't have anything to do with AutoStore
the code is just to make the demo look nice

--]]


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

	if e.phase == 'began' then
		createNewUFO( { x=e.x, y=e.y } )
	end

	return true
end


local function clearButtonTouchHandler( e )
	--print( "clearButtonTouchHandler" )

	if e.phase == 'ended' then

		if dg_ufo.numChildren > 0 then

			AutoStore.data.ufos = {}

			for i = dg_ufo.numChildren, 1, -1 do
				dg_ufo:remove( i )
			end

		end
	end

	return true
end


-- initializeApp()
--
-- 
local function initializeApp()
	--print( "initializeApp" )

	local o

	dg_bg = display.newGroup()
	dg_ufo = display.newGroup()
	dg_fg = display.newGroup()


	o = display.newImageRect( "assets/space_bg.png", 480, 320 )
	o.x = 240 ; o.y = 160

	o:addEventListener( "touch", backgroundTouchHandler )
	dg_bg:insert( o )

	-- clear button

	o = display.newRoundedRect( 395, 5, 70, 30, 4 )
	o.strokeWidth = 2
	o:setStrokeColor( 255, 100, 100 )
	o:setFillColor( 200, 200, 200 )
	o:addEventListener( "touch", clearButtonTouchHandler )

	dg_fg:insert( o )

	o = display.newText( "Clear", 407, 6, nil, 18 )
	o:setTextColor( 0, 0, 0 )
	dg_fg:insert( o )

	-- MIN label & progress bar 
	o = display.newText( "Min", 15, -2, nil, 14 )
	dg_bg:insert( o )

	o = ProgressBar.create( { x=60, y=10, width=310, height=8, color='orange' } )
	min_bar = o
	dg_bg:insert( o._dg )


	-- MAX label & progress bar
	o = display.newText( "Max", 15, 17, nil, 14 )
	dg_bg:insert( o )

	o = ProgressBar.create( { x=60, y=30, width=310, height=8, color='red' } )
	max_bar = o
	dg_bg:insert( o._dg )


	-- "Data Saved" display
	o = display.newText( "Data Saved !!", 160, 100, native.systemFontBold, 24 )
	o:setTextColor(255, 0, 0)
	o.alpha = 0
	saved_text = o
	dg_fg:insert( o )

	AutoStore:addEventListener( AutoStore.AUTOSTORE_EVENT, autostoreEventHandler )


end



-- main()
-- bootstrap the application
--
local main = function()

	initializeApp()

	initializeAutoStore()

	createExistingUFOs()

end


-- let's get this party started !
--
main()




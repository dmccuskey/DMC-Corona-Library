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



--===================================================================--
-- Setup, Constants
--===================================================================--

display.setStatusBar( display.HiddenStatusBar )



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

	data.ufos:insert( ufo )

end


--===================================================================--
-- Main
--===================================================================--


-- createObjects()
--
-- app start, so let's read our data and create any UFOs
--
local function createObjects()
	--print( "createObjects" )

	local ufos = AutoStore.data.ufos
	local o -- ufo object ref

	-- loop through 'ufos' container and create objects
	for _, data in ufos:ipairs() do
		o = UFOFactory.create( data )
	end

end



-- main()
--
local main = function()

	initializeAutoStore()
	createObjects()

end


-- let's get this party started !
--
main()




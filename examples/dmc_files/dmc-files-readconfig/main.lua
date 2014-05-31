--====================================================================--
-- dmc_files
--
-- Read Config File example
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--


print( '\n\n##############################################\n\n' )


--====================================================================--
-- Imports

local File = require 'dmc_corona.dmc_files'
local Utils = require 'dmc_corona.dmc_utils'


--====================================================================--
-- Setup, Constants

local DMC_LIBRARY_CONFIG_FILE = 'dmc_corona.cfg'
local DMC_LIBRARY_DEFAULT_SECTION = 'dmc_corona'


--====================================================================--
-- Main
--====================================================================--


local file_path, options, config_data

file_path = system.pathForFile( DMC_LIBRARY_CONFIG_FILE, system.ResourceDirectory )
assert( file_path ~= nil, "missing path to file: ".. DMC_LIBRARY_CONFIG_FILE )

options = {
	default_section=DMC_LIBRARY_DEFAULT_SECTION
}
config_data = File.readConfigFile( file_path, options )

Utils.print( config_data )


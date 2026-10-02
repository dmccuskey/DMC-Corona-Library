--====================================================================--
-- dmc_corona/dmc_files.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-files
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2013-2015 David McCuskey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Corona Library : DMC Files
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona



--====================================================================--
--== DMC Files
--====================================================================--



--====================================================================--
--== Imports


local LuaFiles = require 'lib.dmc_lua.lua_files'
local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Configuration


dmc_lib_data.dmc_files = dmc_lib_data.dmc_files or {}

local DMC_FILES_DEFAULTS = {
	-- none
}

local dmc_files_data = Utils.extend( dmc_lib_data.dmc_files, DMC_FILES_DEFAULTS )



--====================================================================--
--== Corona File Module
--====================================================================--


-- a copy of lua-files' module, so the shared one, which other
-- modules get from 'lib.dmc_lua.lua_files', keeps its own
-- path-based fileExists() and remove()
--
local File = {}
for k, v in pairs( LuaFiles ) do File[ k ] = v end

File.VERSION = VERSION


--======================================================--
-- fileExists()

-- http://docs.coronalabs.com/api/library/system/pathForFile.html
-- true for a file in storage, false for a folder or a missing file
--
function File.fileExists( filename, options )
	options = options or {}
	local base_dir = options.base_dir or system.DocumentsDirectory

	-- nil for a missing file in system.ResourceDirectory
	local file_path = system.pathForFile( filename, base_dir )
	if file_path == nil then return false end
	return LuaFiles.fileExists( file_path )
end


--======================================================--
-- remove()

-- @param  items  what to remove:
--   a name of a file or folder in options.base_dir
--   a Solar2D folder, such as system.TemporaryDirectory: emptied
--   a list of either
-- @param  options
--   base_dir -- the folder names are in (default system.DocumentsDirectory)
--   rm_dir -- false keeps the folders, emptied (default true)
--
-- a missing name is skipped; a file that can't be removed raises
-- the error from os.remove()
--
function File.remove( items, options )
	-- print( "File.remove" )
	options = options or {}
	local base_dir = options.base_dir or system.DocumentsDirectory

	local i_type = type( items )

	if i_type == 'table' then
		for _, item in ipairs( items ) do
			File.remove( item, options )
		end

	elseif i_type == 'userdata' then
		-- a Solar2D folder: remove what's in it, not the folder
		local dir_path = system.pathForFile( '', items )
		assert( dir_path ~= nil, "no path for the folder" )
		LuaFiles._removeDir( dir_path, options )

	elseif i_type == 'string' then
		-- nil for a missing file in system.ResourceDirectory
		local path = system.pathForFile( items, base_dir )
		if path ~= nil then LuaFiles.remove( path, options ) end

	else
		error( "expected a name, a Solar2D folder or a list, got "..i_type )
	end
end




return File

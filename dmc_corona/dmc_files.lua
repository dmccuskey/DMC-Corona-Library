--====================================================================--
-- dmc_corona/dmc_files.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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

local VERSION = "1.1.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--


--====================================================================--
--== Support Functions


local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end



--====================================================================--
--== Configuration


local dmc_lib_data, dmc_lib_info

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
--== Configuration


dmc_lib_data.dmc_files = dmc_lib_data.dmc_files or {}

local DMC_FILES_DEFAULTS = {
	-- none
}

local dmc_files_data = Utils.extend( dmc_lib_data.dmc_files, DMC_FILES_DEFAULTS )



--====================================================================--
--== Imports


local lfs = require 'lfs'
local File = require 'lib.dmc_lua.lua_files'



--====================================================================--
--== Corona File Module
--====================================================================--


--======================================================--
-- fileExists()

-- http://docs.coronalabs.com/api/library/system/pathForFile.html
-- check to see if a file already exists in storage
--
function File.fileExists( filename, options )

	options = options or {}
	if options.base_dir == nil then options.base_dir = system.DocumentsDirectory end

	local file_path = system.pathForFile( filename, options.base_dir )
	return LuaFile.fileExists( file_path, options )
end


--======================================================--
-- remove()

-- item is a path
function File._removeFile( f_path, f_options )
		local success, msg = os.remove( f_path )
		if not success then
			print( "ERROR: removing " .. f_path )
			print( "ERROR: " .. msg )
		end
end

function File._removeDir( dir_path, dir_options )
	for f_name in lfs.dir( dir_path ) do
		if f_name == '.' or f_name == '..' then
			-- skip system files
		else
			local f_path = dir_path .. '/' .. f_name
			local f_mode = lfs.attributes( f_path, 'mode' )

			if f_mode == 'directory' then
				File._removeDir( f_path, dir_options )
				if dir_options.rm_dir == true then
					File._removeFile( f_path, dir_options )
				end
			elseif f_mode == 'file' then
				File._removeFile( f_path, dir_options )
			end

		end -- if f_name
	end
end


-- name could be :
-- user data
-- string of file
-- string of directory names
-- table of files
-- table of dir names

-- @param  items  name of file to remove, string or table of strings, if directory
-- @param  options
--   dir -- directory, system.DocumentsDirectory, system.TemporaryDirectory, etc
--
-- if name -- name and dir, removes files in directory
function File.remove( items, options )
	-- print( "File.remove" )
	options = options or {}
	if options.base_dir == nil then options.base_dir = system.DocumentsDirectory end
	if options.rm_dir == nil then options.rm_dir = true end

	local f_type, f_path, f_mode
	local opts

	f_type = type( items )

	-- if items is Corona system directory
	if f_type == 'userdata' then
		f_path = system.pathForFile( '', items )
		File._removeDir( f_path, options )

	-- if items is name of a directory
	elseif f_type == 'string' then
		f_path = system.pathForFile( items, options.base_dir )
		f_mode = lfs.attributes( f_path, 'mode' )

		if f_mode == 'directory' then
			rm_dir( f_path, options )
			if options.rm_dir == true then
				File._removeFile( f_path, options )
			end

		elseif f_mode == 'file' then
			File._removeFile( f_path, options )
		end

	-- if items is list of names
	elseif f_type == 'table' then

	end

end




return File

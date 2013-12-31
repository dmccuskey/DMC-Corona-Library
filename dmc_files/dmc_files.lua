
--====================================================================--
-- dmc_files.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_files.lua
--====================================================================--


--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
-- DMC Library Support Methods
--====================================================================--

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
-- DMC Library Config
--====================================================================--

local dmc_lib_data, dmc_lib_info, dmc_lib_location

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_library_boot" ) end ) then
	_G.__dmc_library = {
		dmc_library={
			location = ''
		},
		func = {
			find=function( name )
				local loc = ''
				if dmc_lib_data[name] and dmc_lib_data[name].location then
					loc = dmc_lib_data[name].location
				else
					loc = dmc_lib_info.location
				end
				if loc ~= '' and string.sub( loc, -1 ) ~= '.' then
					loc = loc .. '.'
				end
				return loc .. name
			end
		}
	}
end

dmc_lib_data = _G.__dmc_library
dmc_lib_func = dmc_lib_data.func
dmc_lib_info = dmc_lib_data.dmc_library
dmc_lib_location = dmc_lib_info.location




--====================================================================--
-- DMC Library : DMC Files
--====================================================================--



--====================================================================--
-- DMC Files Config
--====================================================================--

dmc_lib_data.dmc_files = dmc_lib_data.dmc_files or {}

local DMC_FILES_DEFAULTS = {
	-- none
}

local dmc_files_data = Utils.extend( dmc_lib_data.dmc_files, DMC_FILES_DEFAULTS )



--====================================================================--
-- Imports
--====================================================================--

local lfs = require( 'lfs' )
local json = require( 'json' )



--====================================================================--
-- Setup, Constants
--====================================================================--

local Files = {}

Files.IO_ERROR = "io_error"
Files.IO_SUCCESS = "io_success"


--====================================================================--
-- Support Methods
--====================================================================--



--====================================================================--
-- Files Module
--====================================================================--



--====================================================================--
--== fileExists() ==--


-- pure Lua functionality
--
function Files._fileExists( file_path, options )
	local exists = false
	local fh = io.open( file_path, "r" )
	if fh then
		fh:close()
		exists = true
	end
	return exists

end

-- http://docs.coronalabs.com/api/library/system/pathForFile.html
-- check to see if a file already exists in storage
--
function Files.fileExists( filename, options )

	options = options or {}
	if options.base_dir == nil then options.base_dir = system.DocumentsDirectory end

	local file_path = system.pathForFile( filename, options.base_dir )
	return Files._fileExists( file_path, options )
end



--====================================================================--
--== remove() ==--


-- item is a path
function Files._removeFile( f_path, f_options )
		local success, msg = os.remove( f_path )
		if not success then
			print( "ERROR: removing " .. f_path )
			print( "ERROR: " .. msg )
		end
end

function Files._removeDir( dir_path, dir_options )
	for f_name in lfs.dir( dir_path ) do
		if f_name == '.' or f_name == '..' then
			-- skip system files
		else
			local f_path = dir_path .. '/' .. f_name
			local f_mode = lfs.attributes( f_path, 'mode' )

			if f_mode == 'directory' then
				Files._removeDir( f_path, dir_options )
				if dir_options.rm_dir == true then
					Files._removeFile( f_path, dir_options )
				end
			elseif f_mode == 'file' then
				Files._removeFile( f_path, dir_options )
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
function Files.remove( items, options )
	-- print( "Files.remove" )
	options = options or {}
	if options.base_dir == nil then options.base_dir = system.DocumentsDirectory end
	if options.rm_dir == nil then options.rm_dir = true end

	local f_type, f_path, f_mode
	local opts

	f_type = type( items )

	-- if items is Corona system directory
	if f_type == 'userdata' then
		f_path = system.pathForFile( '', items )
		Files._removeDir( f_path, options )

	-- if items is name of a directory
	elseif f_type == 'string' then
		f_path = system.pathForFile( items, options.base_dir )
		f_mode = lfs.attributes( f_path, 'mode' )

		if f_mode == 'directory' then
			rm_dir( f_path, options )
			if options.rm_dir == true then
				Files._removeFile( f_path, options )
			end

		elseif f_mode == 'file' then
			Files._removeFile( f_path, options )
		end


	-- if items is list of names
	elseif f_type == 'table' then

	end

end



--====================================================================--
--== readFile() ==--


function Files.readFile( file_path, options )
	-- print( "Files.readFile", file_path )

	options = options or {}
	if options.lines == nil then options.lines = true end

	local contents -- either string or table of strings
	local ret_val = {} -- an array, [ status, content ]

	if file_path == nil then
		local ret_val = { Files.IO_ERROR, "file path is NIL" }

	else
		local fh, reason = io.open( file_path, "r" )
		if fh == nil then
			print("ERROR: datastore load settings: " .. tostring( reason ) )
			ret_val = { Files.IO_ERROR, reason }

		else
			if options.lines == false then
				-- read contents in one big string
				contents = fh:read( '*all' )

			else
				-- read all contents of file into a table
				contents = {}
				for line in fh:lines() do
					table.insert( contents, line )
				end

			end

			ret_val = { Files.IO_SUCCESS, contents }
			io.close( fh )

		end  -- fh == nil
	end  -- file_path == nil

	return ret_val[1], ret_val[2]
end



--====================================================================--
--== saveFile() ==--


function Files.saveFile( file_path, data )
	-- print( "Files.saveFile" )

	local ret_val = {} -- an array, [ status, content ]

	local fh, reason = io.open( file_path, "w" )
	if fh then
		fh:write( data )
		io.close( fh )
		ret_val = { Files.IO_SUCCESS, data }
	else
		print("ERROR: dmc_files save: " .. tostring( reason ) )
		ret_val = { Files.IO_ERROR, reason }
	end
	return ret_val

end



--====================================================================--
--== readJSONFile() ==--


function Files.readJSONFile( file_path, options )
	-- print( "Files.readJSONFile", file_path )

	local options = options or {}
	local status, content = Files.readFile( file_path, { lines=false } )
	local data = nil

	if content then
		data = json.decode( content )
		if data == nil then
			error( "ERROR DMC File: reading JSON file, probably malformed data", 2 )
		end
	end

	return data

end



--====================================================================--
--== saveJSONFile() ==--


-- data is a plain Lua table/memory structure
-- returns status / content
function Files.saveJSONFile( file_path, data )

	local content = json.encode( data )
	return Files.saveFile( file_path, content )

end



--====================================================================--
--== readConfigFile() ==--


function Files.readConfigFile( file_path, options )
	-- print( "Files.readConfigFile", file_path )

	options = options or {}
	options.lines = true
	options.default_section = options.default_section or nil -- no default here

	local status, contents = Files.readFile( file_path, options )

	if status == Files.IO_ERROR then return nil end

	local data = {}
	local curr_section = options.default_section
	if curr_section ~= nil and not data[curr_section] then
		data[curr_section]={}
	end

	local function castValue( v, t )
		local ret = nil

		if t == 'PATH' or t == 'FILE' then
			ret = string.gsub( v, '[/\\]', "." )
		elseif t == 'BOOL' or t == 'BOOLEAN' then
			if v == 'true' then
				ret = true
			elseif v == 'false' then
				ret = false
			end
		elseif t == 'INT' or t == 'INTEGER' then
			ret = tonumber( v )
		elseif t == 'STR' or t == 'STRING' then
			ret = v
		end

		if ret == nil then ret = v end -- return orig value

 		return ret
	end

	local function processSectionLine( line )
		local key
		key = line:match( "%[([%w_]+)%]" )
		key = string.lower( key ) -- use only lowercase inside of module
		return key
	end

	local function processKeyLine( line )
		local k, v, key, val
		-- print( line )
		local parts = { nil, 'STRING', nil } -- holds key, type, value
		k, v = line:match( "([%w_:]+)%s*=%s*([%w_./\\]+)" )
		parts[3] = v -- value
		local i = 1
		for x in k:gmatch( "[%a_]+" ) do
			parts[i] = x
		  i = i + 1
		end
		-- print( tostring(parts[1]) .. " (".. tostring( parts[2]) .. ") = " .. tostring(parts[3]) )

		key = string.lower( parts[1] ) -- use only lowercase inside of module
		val = castValue( parts[3], parts[2]  )
		-- print( key, val, type(val) )
		return key, val
	end

	local is_valid = true
	local is_section
	local key, val
	for _, line in ipairs( contents ) do
		-- print( line )
		is_section = ( string.find( line, '%[%w', 1, false ) == 1 )
		is_key = ( string.find( line, '%w', 1, false ) == 1 )
		-- print( is_section, is_key )

		if is_section then
			curr_section = processSectionLine( line )
			if not data[curr_section] then data[curr_section]={} end
		elseif is_key and curr_section ~= nil then
			key, val = processKeyLine( line )
			data[curr_section][key] = val
		end
	end

	return data
end



return Files

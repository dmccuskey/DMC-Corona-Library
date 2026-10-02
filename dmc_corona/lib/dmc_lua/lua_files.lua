--====================================================================--
-- dmc_lua/lua_files.lua
--
-- Documentation: https://github.com/dmccuskey/lua-files
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014-2015 David McCuskey. All Rights Reserved.

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
--== DMC Lua Library : Lua Files
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.3.0"



--====================================================================--
--== Imports


local Utils = require 'lua_utils'

-- only fileExists() and remove() use lfs
local ok, lfs = pcall( require, 'lfs' )
if not ok then lfs = nil end

local ok, json = pcall( require, 'json' )
if not ok then
	print( "WARNING: lua_files missing json module" )
	json = nil
end



--====================================================================--
--== Lua File Module
--====================================================================--


local File = {}
File.__version = VERSION
File.NAME = "Lua Files"

--== Class constants ==--

File.DEFAULT_CONFIG_SECTION = 'default'


--======================================================--
-- fileExists()

-- true for a file, false for a folder or a missing path
-- without lfs: true when the path can be opened for reading
--
function File.fileExists( file_path )
	-- print( "File.fileExists", file_path )
	if lfs then
		return lfs.attributes( file_path, 'mode' ) == 'file'
	end
	local fh = io.open( file_path, 'r' )
	if not fh then return false end
	io.close( fh )
	return true
end


--======================================================--
-- remove()

-- a symbolic link is removed itself, never followed
local function getPathMode( path )
	local attributes = lfs.symlinkattributes or lfs.attributes
	local mode = attributes( path, 'mode' )
	if mode == 'link' then mode = 'file' end
	return mode
end

-- item is a path
function File._removeFile( f_path, f_options )
	local ok, msg = os.remove( f_path )
	if not ok then error( msg, 0 ) end
end

-- removes everything in the folder; its subfolders too
-- unless f_options.rm_dir is false (then they are emptied)
--
function File._removeDir( dir_path, dir_options )
	assert( lfs ~= nil, 'Lua File System (lfs) not loaded' )
	--==--
	local rm_dir = not ( dir_options and dir_options.rm_dir == false )

	-- collect first: removing entries while lfs.dir() walks them
	-- isn't safe on every platform
	local names = {}
	for f_name in lfs.dir( dir_path ) do
		if f_name ~= '.' and f_name ~= '..' then
			table.insert( names, f_name )
		end
	end

	for _, f_name in ipairs( names ) do
		local f_path = dir_path .. '/' .. f_name
		local f_mode = getPathMode( f_path )

		if f_mode == 'directory' then
			File._removeDir( f_path, dir_options )
			if rm_dir then File._removeFile( f_path, dir_options ) end
		elseif f_mode ~= nil then
			File._removeFile( f_path, dir_options )
		end
	end
end


-- @param  paths  a path, file or folder, or a list of paths
-- @param  options
--   rm_dir -- false keeps the folders, emptied (default true)
--
-- a missing path is skipped; a path that can't be removed raises
-- the error from os.remove()
--
function File.remove( paths, options )
	-- print( "File.remove" )
	assert( lfs ~= nil, 'Lua File System (lfs) not loaded' )
	--==--

	if type( paths ) == 'table' then
		for _, path in ipairs( paths ) do
			File.remove( path, options )
		end
		return
	end
	assert( type( paths ) == 'string', "expected a path or a list of paths" )

	local f_mode = getPathMode( paths )
	if f_mode == 'directory' then
		File._removeDir( paths, options )
		if not ( options and options.rm_dir == false ) then
			File._removeFile( paths, options )
		end
	elseif f_mode ~= nil then
		File._removeFile( paths, options )
	end
end


--======================================================--
-- readFile()

function File._openCloseFile( file_path, read_f, options )
	-- print( "File.readFile", file_path )
	assert( type(file_path)=='string', "file path is not string" )
	assert( type(read_f)=='function', "read function is not function" )
	--==--

	local fh = assert( io.open(file_path, 'r') )
	local contents = read_f( fh )
	io.close( fh )

	return contents
end


function File._readLines( fh )
	local contents = {}
	for line in fh:lines() do
		table.insert( contents, line )
	end
	return contents
end

function File.readFileLines( file_path, options )
	return File._openCloseFile( file_path, File._readLines, options )
end


function File._readContents( fh )
	return fh:read( '*all' )
end

function File.readFileContents( file_path, options )
	return File._openCloseFile( file_path, File._readContents, options )
end


function File.readFile( file_path, options )
	options = options or {}
	--==--
	if options.lines == nil or options.lines == true then
		return File.readFileLines( file_path, options )
	else
		return File.readFileContents( file_path, options )
	end
end


--======================================================--
-- saveFile()

-- full fil epath
function File.saveFile( file_path, data )
	-- print( "File.saveFile" )
	local fh = assert( io.open(file_path, 'w') )
	fh:write( data )
	io.close( fh )
end


--======================================================--
-- read/write JSONFile()

function File.convertLuaToJson( lua_data )
	assert( json ~= nil, 'JSON library not loaded' )
	assert( type(lua_data)=='table' )
	--==--
	return json.encode( lua_data )
end
function File.convertJsonToLua( json_str )
	assert( json ~= nil, 'JSON library not loaded' )
	assert( type(json_str)=='string' )
	assert( #json_str > 0, "JSON string is empty" )
	--==--
	local data = json.decode( json_str )
	assert( data~=nil, "Error reading JSON file, probably malformed data" )
	return data
end


function File.readJSONFile( file_path, options )
	-- print( "File.readJSONFile", file_path )
	options = options or {}
	--==--
	local contents = File.readFileContents( file_path, options )
	assert( #contents > 0, "JSON file is empty: " .. tostring( file_path ) )
	return File.convertJsonToLua( contents )
end

-- @param file_path full file-path string to location
-- @param lua_data plain Lua table/memory structure
--
function File.writeJSONFile( file_path, lua_data, options )
	-- print( "File.writeJSONFile", file_path )
	return File.saveFile( file_path, File.convertLuaToJson( lua_data ) )
end


--======================================================--
-- readConfigFile()

-- types of possible keys for a line
local KEY_TYPES = { 'boolean', 'bool', 'file', 'integer', 'int', 'json', 'path', 'string', 'str' }

function File.getLineType( line )
	-- print( "File.getLineType", #line, line )
	assert( type(line)=='string' )
	--==--
	local is_section, is_key = false, false
	if #line > 0 then
		is_section = ( string.find( line, '%[%u', 1, false ) == 1 )
		is_key = ( string.find( line, '%u', 1, false ) == 1 )
	end
	return is_section, is_key
end

function File.processSectionLine( line )
	-- print( "File.processSectionLine", line )
	assert( type(line)=='string', "expected string as parameter" )
	assert( #line > 0 )
	--==--
	local key = line:match( "^%[(%u[%w_]*)%]" )
	assert( type(key) ~= 'nil', "key not found in line: "..tostring(line) )
	return string.lower( key ) -- use only lowercase inside of module
end

function File.processKeyLine( line )
	-- print( "File.processKeyLine", line )
	assert( type(line)=='string', "expected string as parameter" )
	assert( #line > 0 )
	--==--

	-- split up line into key/value, KEY:TYPE = value or KEY = value
	local key_name, key_type, raw_val = line:match( "^(%u[%w_]*)%s*:%s*(%w+)%s*=%s*(.-)%s*$" )
	if key_name == nil then
		key_name, raw_val = line:match( "^(%u[%w_]*)%s*=%s*(.-)%s*$" )
	end
	assert( key_name ~= nil, "expected KEY = value in line: "..tostring(line) )

	-- trim off quotes, make sure balanced
	local q1, q2, trim
	q1, trim, q2 = raw_val:match( "^(['\"]?)(.-)(['\"]?)$" )
	assert( q1 == q2, "quotes must match" )

	-- process key and value
	key_name = File.processKeyName( key_name )
	key_type = File.processKeyType( key_type )

	-- get final value
	local key_value
	if key_type == nil then
		key_value = File.castTo_string( trim )
	else
		assert( Utils.propertyIn( KEY_TYPES, key_type ), "unknown type '"..key_type.."' in line: "..tostring(line) )
		key_value = File[ 'castTo_'..key_type ]( trim )
	end

	return key_name, key_value
end

function File.processKeyName( name )
	-- print( "File.processKeyName", name )
	assert( type(name)=='string', "expected string as parameter" )
	assert( #name > 0, "no length for name" )
	--==--
	return string.lower( name ) -- use only lowercase inside of module
end
-- allows nil to be passed in
function File.processKeyType( name )
	-- print( "File.processKeyType", name )
	--==--
	if type(name)=='string' then
		name = string.lower( name ) -- use only lowercase inside of module
	end
	return name
end


-- 'true' or 'false', any case
function File.castTo_boolean( value )
	assert( type(value)=='string' )
	--==--
	local lower = string.lower( value )
	assert( lower == 'true' or lower == 'false', "expected true or false, got '"..value.."'" )
	return lower == 'true'
end
File.castTo_bool = File.castTo_boolean

function File.castTo_file( value )
	return File.castTo_string( value )
end
function File.castTo_integer( value )
	assert( type(value)=='string' )
	--==--
	local num = tonumber( value )
	assert( type(num) == 'number' and num == math.floor( num ), "expected a whole number, got '"..value.."'" )
	return num
end
File.castTo_int = File.castTo_integer

function File.castTo_json( value )
	assert( type(value)=='string' )
	--==--
	return File.convertJsonToLua( value )
end
function File.castTo_path( value )
	assert( type(value)=='string' )
	--==--
	return ( string.gsub( value, '[/\\]', "." ) )
end
function File.castTo_string( value )
	assert( type(value)~='nil' and type(value)~='table' )
	return tostring( value )
end
File.castTo_str = File.castTo_string


function File.parseFileLines( lines, options )
	-- print( "parseFileLines", #lines )
	assert( options, "options parameter expected" )
	assert( options.default_section, "options table requires 'default_section' entry" )
	--==--

	local curr_section = options.default_section

	local config_data = {}
	config_data[ curr_section ]={}

	for _, line in ipairs( lines ) do
		local is_section, is_key = File.getLineType( line )
		-- print( line, is_section, is_key )

		if is_section then
			curr_section = File.processSectionLine( line )
			if not config_data[ curr_section ] then
				config_data[ curr_section ]={}
			end

		elseif is_key then
			local key, val = File.processKeyLine( line )
			config_data[ curr_section ][key] = val

		end
	end

	return config_data
end

-- @param file_path string full path to file
--
function File.readConfigFile( file_path, options )
	-- print( "File.readConfigFile", file_path )
	options = options or {}
	options.default_section = options.default_section or File.DEFAULT_CONFIG_SECTION
	--==--

	return File.parseFileLines( File.readFileLines( file_path ), options )
end



return File

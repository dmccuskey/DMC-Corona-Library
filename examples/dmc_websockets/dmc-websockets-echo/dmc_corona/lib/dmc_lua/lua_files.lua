--====================================================================--
-- dmc_lua/lua_files.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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

local VERSION = "0.2.0"



--====================================================================--
--== Imports


local Error = require 'lua_error' -- try/catch
local Utils = require 'lua_utils'

local ok, lfs = pcall( require, 'lfs' )
if not ok then
	print( "WARNING: lua_files missing lfs module" )
	lfs = nil
end

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

function File.fileExists( file_path )
	-- print( "File.fileExists", file_path )
	local fh, exists
	try{
		function()
			fh = assert( io.open( file_path, 'r' ) )
			io.close( fh )
			exists = true
		end,
		catch{
			function()
				exists = false
			end
		}
	}
	return exists
end


--======================================================--
-- remove()

-- item is a path
function File._removeFile( f_path, f_options )
	assert( os.remove( f_path ) )
end

function File._removeDir( dir_path, dir_options )
	assert( lsf ~= nil, 'Lua File System (lfs) not loaded' )
	--==--

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
	options.lines = options.lines == nil and true or options.lines
	--==--
	if options.lines == true then
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
	assert( #json_str > 0 )
	--==--
	local data = json.decode( json_str )
	assert( data~=nil, "Error reading JSON file, probably malformed data" )
	return data
end


function File.readJSONFile( file_path, options )
	-- print( "File.readJSONFile", file_path )
	options = options or {}
	--==--
	return File.convertJsonToLua( File.readFileContents( file_path, options ) )
end

-- @param file_path full file-path string to location
-- @param lua_data plain Lua table/memory structure
--
function File.writeJSONFile( file_path, lua_data, options )
	-- print( "File.writeJSONFile", file_path )
	return File.writeFile( file_path, File.convertLuaToJson( lua_data ), options )
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
	local key = line:match( "%[([%u_]+)%]" )
	assert( type(key) ~= 'nil', "key not found in line: "..tostring(line) )
	return string.lower( key ) -- use only lowercase inside of module
end

function File.processKeyLine( line )
	-- print( "File.processKeyLine", line )
	assert( type(line)=='string', "expected string as parameter" )
	assert( #line > 0 )
	--==--

	-- split up line into key/value
	local raw_key, raw_val = line:match( "([%u_:]+)%s*=%s*(.-)%s*$" )

	-- split up key parts
	local keys = {}
	for k in string.gmatch( raw_key, "([^:]+)") do
		table.insert( keys, #keys+1, k )
	end

	-- trim off quotes, make sure balanced
	local q1, q2, trim
	q1, trim, q2 = raw_val:match( "^(['\"]?)(.-)(['\"]?)$" )
	assert( q1 == q2, "quotes must match" )

	-- process key and value
	local key_name, key_type = unpack( keys )
	key_name = File.processKeyName( key_name )
	key_type = File.processKeyType( key_type )

	-- get final value
	if key_type and Utils.propertyIn( KEY_TYPES, key_type ) then
		local method = 'castTo_'..key_type
		key_value = File[method]( trim )
	else
		key_value = File.castTo_string( trim )
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


function File.castTo_boolean( value )
	assert( type(value)=='string' )
	--==--
	if value == 'true' then return true
	else return false end
end
File.castTo_bool = File.castTo_boolean

function File.castTo_file( value )
	return File.castTo_string( value )
end
function File.castTo_integer( value )
	assert( type(value)=='string' )
	--==--
	local num = tonumber( value )
	assert( type(num) == 'number' )
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
	return string.gsub( value, '[/\\]', "." )
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

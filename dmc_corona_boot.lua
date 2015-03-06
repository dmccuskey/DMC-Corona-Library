--====================================================================--
-- dmc_corona_boot.lua
--
--  utility to read in configuration file for dmc-corona-library
--
-- Documentation:
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : DMC Corona Boot
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.5.1"



--====================================================================--
--== Imports


local has_json, json = pcall( require, 'json' )
if not has_json then json = nil end



--====================================================================--
--== Setup, Constants


local sfind = string.find
local sgsub = string.gsub
local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove

local PLATFORM_NAME = system.getInfo( 'platformName' )



--====================================================================--
--== Setup Support
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

-- split string up in parts, using separator
-- returns array of pieces
function Utils.split( str, sep )
	if sep == nil then
		sep = "%s"
	end
	local t, i = {}, 1
	for str in string.gmatch( str, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end


function Utils.getSystemSeparator()
	-- print( "Utils.getSystemSeparator")
	if PLATFORM_NAME == 'Win' then
		return '\\'
	else
		return '/'
	end
end

function Utils.propertyIn( list, property )
	for i = 1, #list do
		if list[i] == property then return true end
	end
	return false
end


-- takes Lua module dot to system path
-- eg, lib.dmc_lua.lua_object >> lib/dmc_lua/lua_object
--
function Utils.sysPathToRequirePath( sys_path )
	-- print( "sysPathToRequirePath", sys_path )
	local sys_tbl = Utils.split( sys_path, Utils.getSystemSeparator() )
	-- clean off any dots
	for i=#sys_tbl, 1, -1 do
		if sys_tbl[i]=='.' then
			tremove( sys_tbl, i )
		end
	end
	return tconcat( sys_tbl, '.' )
end

-- takes Lua module dot to system path
-- eg, lib.dmc_lua.lua_object >> lib/dmc_lua/lua_object
--
function Utils.cleanSystemPath( sys_path )
	-- print( "cleanSystemPath", sys_path )
	local sep = Utils.getSystemSeparator()
	local sys_tbl = Utils.split( sys_path, sep )
	-- clean off any dots
	for i=#sys_tbl, 1, -1 do
		if sys_tbl[i]=='.' then
			tremove( sys_tbl, i )
		end
	end
	return tconcat( sys_tbl, sep )
end




--== Start lua_files copies ==--

-- version 0.2.0

local File = {}


--======================================================--
-- fileExists()

function File.fileExists( file_path )
	-- print( "File.fileExists", file_path )
	local has_file, _ = pcall( function()
		local result = assert( io.open( file_path, 'r' ) )
		io.close( result )
	end)
	return has_file
end


--====================================================================--
--== readFile() ==--

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
		tinsert( contents, line )
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


--====================================================================--
--== read/write JSONFile() ==--

function File.convertJsonToLua( json_str )
	assert( json ~= nil, 'JSON library not loaded' )
	assert( type(json_str)=='string' )
	assert( #json_str > 0 )
	--==--
	local data = json.decode( json_str )
	assert( data~=nil, "Error reading JSON file, probably malformed data" )
	return data
end


--====================================================================--
--== readConfigFile() ==--

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
		tinsert( keys, #keys+1, k )
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
	local key_value
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

--== End lua_files copies ==--



--====================================================================--
--== Setup DMC Corona Library Config
--====================================================================--


--[[
This is standard code to bootstrap the dmc-corona-library
it looks for a configuration file to read
--]]


local DMC_CORONA_CONFIG_FILE = 'dmc_corona.cfg'
local DMC_CORONA_DEFAULT_SECTION = 'dmc_corona'

-- locations of third party libs used by dmc_corona
local THIRD_LIBS = {}

--- add 'lib/dmc' location
tinsert( THIRD_LIBS, tconcat( {'lib','dmc_lua'}, Utils.getSystemSeparator() ) )

local REQ_STACK = {}


local function pushStack( value )
	-- print( "pre stack (pre):", #REQ_STACK)
	tinsert( REQ_STACK, value )
end
local function popStack()
	-- print( "pop stack (pre):", #REQ_STACK)
	if REQ_STACK == 0 then
		-- print( "nothing ins stack")
		error( "!!!! nothing in stack" )
	end
	return tremove( REQ_STACK )
end

local wrapError, unwrapError, processError

wrapError = function( stack, message, level )
	-- we package or unpackage
	local package = { stack, message, level }
	return processError( stack, package )
end
unwrapError = function( package )
	return unpack( package )
end
processError = function( stack, package )
	if stack==0 then
		local stack, message, level = unwrapError( package )
		return message, level
	else
		return package
	end
end


local function newRequireFunction( module_name )
	-- print( "dmc_require: ", module_name )
	assert( type(module_name)=='string', "dmc_require: expected string module name" )
	--==--
	local resource_path = system.pathForFile( system.ResourceDirectory ) or ""

	local _paths = _G.__dmc_require.paths
	local _require = _G.__dmc_require.require
	local lua_paths = Utils.extend( _paths, {} )
	tinsert( lua_paths, 1, '' ) -- add search at root-level

	local err_tbl = {}
	local library, err = nil, nil
	local idx = 1

	pushStack( module_name )

	repeat
		local mod_path = lua_paths[idx]
		local path = ( mod_path=='' and mod_path or mod_path..'.' ) .. module_name


		local has_module, result = pcall( _require, path )
		if has_module then
			library = result

		elseif type( result )=='table' then
			-- this is a packaged error from the call-stack
			-- now we're just trying to show it
			-- so we have to unwind the call-stack

			err = result

		else
			-- we just got error from Lua, so we need to handle it

			if sfind( result, '^module' ) then
				-- "module not found"
				-- pass on this because we could have more places to check

			elseif sfind( result, '^error loading module' ) then
				-- "error loading module"
				-- we can't proceed with this error, so
				-- package up to travel back up call-stack

				result="\n\n"..result
				err = wrapError( #REQ_STACK, result, 2 )

			else
				-- we have some unknown error
				print("other error")
				err = wrapError( #REQ_STACK, result, 3 )
			end

		end

		idx=idx+1
	until err or library or idx > #lua_paths

	popStack()

	if err then
		error( processError( #REQ_STACK, err ) )

	elseif not library then
		-- print("not found")
		local emsg = string.format( "\nThe module '%s' not found in archive:", tostring( module_name) )
		error( wrapError( #REQ_STACK, debug.traceback( emsg ), 3 ))
	end

	return library
end



-- read in the config file for dmc-corona
local function readDMCConfiguration()
	-- print( "readDMCConfiguration" )

	-- check if a module has tried to read config
	if _G.__dmc_corona ~= nil then return end

	local file_path, config_data
	local dmc_lib_data

	file_path = system.pathForFile( DMC_CORONA_CONFIG_FILE, system.ResourceDirectory )
	if file_path ~= nil then
		config_data = File.readConfigFile( file_path, { default_section=DMC_CORONA_DEFAULT_SECTION } )
	end

	-- make sure we have defaults for data areas
	_G.__dmc_corona = config_data or {}
	dmc_lib_data = _G.__dmc_corona
	dmc_lib_data.dmc_corona = dmc_lib_data.dmc_corona or {}

end


local function setupDMCRequireStruct()
	-- print( "setupDMCRequireStruct" )
	if _G.__dmc_require ~= nil then return end
	_G.__dmc_require = {
		paths={},
		require=_G.require, -- orig require method
		pkg_path = package.path -- orig package path
	}
end


local function setupRequireLoading()
	-- print( "setupRequireLoading" )
	if _G.__dmc_require ~= nil then return end

	setupDMCRequireStruct()

	local dmc_corona_info = _G.__dmc_corona.dmc_corona
	local req_paths = _G.__dmc_require.paths
	local sys2reqPath = Utils.sysPathToRequirePath

	local path_info = dmc_corona_info.lua_path or {}

	-- modify the search paths, also adding 3rd party lib locations
	for i=1,#path_info do
		local mod_path, third_path
		mod_path = path_info[i]
		-- print( ">s1", sys2reqPath( mod_path ) )
		tinsert( req_paths, sys2reqPath( mod_path ) )
		for i=1,#THIRD_LIBS do
			third_path = THIRD_LIBS[i]
			-- print( ">s2", sys2reqPath( mod_path..'.'..third_path ) )
			tinsert( req_paths, sys2reqPath( mod_path..'.'..third_path ) )
		end
	end
end


-- useRequireLoading()
-- setup alternate require() method
--
local function useRequireLoading()
	-- print( "useRequireLoading" )

	setupRequireLoading() -- must be first

	_G.require=newRequireFunction

end


-- setupModuleLoadingMethod()
--
local function setupModuleLoadingMethod( )
	-- print( "setupModuleLoadingMethod" )
	setupRequireLoading() -- must be first

	_G.require=newRequireFunction
end


readDMCConfiguration()
setupModuleLoadingMethod()


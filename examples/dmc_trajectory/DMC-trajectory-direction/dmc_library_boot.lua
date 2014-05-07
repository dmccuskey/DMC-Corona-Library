--====================================================================--
-- dmc_library_boot.lua
--
--  utility to read in dmc_library configuration file
--
-- by David McCuskey
-- Documentation:
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

local VERSION = "1.0.1"


--====================================================================--
-- Setup Support Methods
--====================================================================--

local Utils = {} -- make copying from dmc_utils easier

--== Start dmc_utils copies ==--

Utils.IO_ERROR = "io_error"
Utils.IO_SUCCESS = "io_success"

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

function Utils.readFile( file_path, options )
	-- print( "Utils.readFile", file_path )

	options = options or {}
	if options.lines == nil then options.lines = true end

	local contents -- either string or table of strings
	local ret_val = {} -- an array, [ status, content ]

	if file_path == nil then
		local ret_val = { Utils.IO_ERROR, "file path is NIL" }

	else
		local fh, reason = io.open( file_path, "r" )
		if fh == nil then
			print("ERROR: datastore load settings: " .. tostring( reason ) )
			ret_val = { Utils.IO_ERROR, reason }

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

			ret_val = { Utils.IO_SUCCESS, contents }
			io.close( fh )

		end  -- fh == nil
	end  -- file_path == nil

	return ret_val[1], ret_val[2]
end

function Utils.readConfigFile( file_path, options )
	-- print( "Utils.readConfigFile", file_path )

	options = options or {}
	options.lines = true
	options.default_section = options.default_section or nil -- no default here

	local status, contents = Utils.readFile( file_path, options )

	if status == Utils.IO_ERROR then return nil end

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

--== End dmc_utils copies ==--



--====================================================================--
-- Setup DMC Library Config
--====================================================================--

-- This is standard code to bootstrap the dmc_library
-- it looks for a configuration file to read in

local DMC_LIBRARY_CONFIG_FILE = 'dmc_library.cfg'
local DMC_LIBRARY_DEFAULT_SECTION = 'dmc_library'

local dmc_lib_data, dmc_lib_info -- variable 'aliases'

-- check to see if a module has tried to read in our config file
if _G.__dmc_library == nil then

	local file_path, config_data
	file_path = system.pathForFile( DMC_LIBRARY_CONFIG_FILE, system.ResourceDirectory )
	if file_path == nil then
		config_data = {}
	else
		config_data = Utils.readConfigFile( file_path, { default_section=DMC_LIBRARY_DEFAULT_SECTION } )
	end

	_G.__dmc_library = config_data
	dmc_lib_data = _G.__dmc_library  -- set 'alias'

	dmc_lib_data.dmc_library = dmc_lib_data.dmc_library or {}
	dmc_lib_info = dmc_lib_data.dmc_library  -- set 'alias'

	if dmc_lib_info.location == nil then
		dmc_lib_info.location = ''
	else
		dmc_lib_info.location = string.gsub( dmc_lib_info.location, '[/\\]', "." )
	end

	--== Setup utility functions

	dmc_lib_data.func = {}

	-- create find() utility
	dmc_lib_data.func.find = function( name )
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

end


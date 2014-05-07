--====================================================================--
-- dmc_utils.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_utils.lua
--====================================================================--


--[[

Copyright (C) 2011-2014 David McCuskey. All Rights Reserved.

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

local VERSION = "0.8.1"




--====================================================================--
-- DMC Library Support Methods
--====================================================================--

local Utils = {}

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
-- DMC Library : DMC Utils
--====================================================================--




--====================================================================--
-- DMC Utils Config
--====================================================================--

dmc_lib_data.dmc_utils = dmc_lib_data.dmc_utils or {}

local DMC_UTILS_DEFAULTS = {
	-- none
}

local dmc_utils_data = Utils.extend( dmc_lib_data.dmc_utils, DMC_UTILS_DEFAULTS )



--====================================================================--
-- Imports
--====================================================================--



--====================================================================--
-- Table Functions
--====================================================================--


-- extend()
-- Copy key/values from one table to another
-- Will deep copy any value from first table which is itself a table.
--
-- @param fromTable the table (object) from which to take key/value pairs
-- @param toTable the table (object) in which to copy key/value pairs
-- @return table the table (object) that received the copied items
--
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


-- hasOwnProperty()
-- Find a property directly on an object (not via inheritance prototype)
--
-- @param table the table (object) to search
-- @param prop the name (string) of the property to find
-- @return true if property is found, false otherwise
--
function Utils.hasOwnProperty( table, property )
	if rawget( table, property ) ~= nil then
		return true
	end
	return false
end


-- propertyIn()
-- Determines whether a property is within a list of items in a table (acting as an array)
--
-- @param list the table with *list* of properties
-- @param property the name of the property to search for
--
function Utils.propertyIn( list, property )
	for i = 1, #list do
		if list[i] == property then return true end
	end
	return false
end


-- destroy()
-- Deletes all of the items in a table structure.
-- This is intended for generic tables and structures, *not* objects
--
-- @param table the table from which to delete contents
--
function Utils.destroy( table )

	if type( table ) ~= "table" then return end

	function _destroy( t )
		for k,v in pairs( t ) do
			if type( t[ k ] ) == "table" then
				_destroy( t[ k ] )
			end
			t[ k ] = nil

		end
	end

	-- start destruction process
	_destroy( table )

end


-- print()
-- print out the keys contained within a table.
-- by default, does not process items with underscore '_'
--
-- @param table the table (object) to print
-- @param include a list of names to include
-- @param exclude a list of names to exclude
--
function Utils.print( table, include, exclude, params )
	local indent = ""
	local step = 0
	local include = include or {}
	local exclude = exclude or {}
	local params = params or {}
	local options = {
		limit = 10,
	}
	opts = Utils.extend( params, options )

	--print("Printing object table =============================")
	function _print( t, ind, s )

		-- limit number of rounds
		if s > options.limit then return end

		for k, v in pairs( t ) do
			local ok_to_process = true

			if Utils.propertyIn( include, k ) then
				ok_to_process = true
			elseif type( t[k] ) == "function" or
				Utils.propertyIn( exclude, k ) or
				type( k ) == "string" and k:sub(1,1) == '_' then
				ok_to_process = false
			end

			if ok_to_process then

				if type( t[ k ] ) == "table" then
					local  o = t[ k ]
					local address = tostring( o )
					local items = #o
					print ( ind .. k .. " --> " .. address .. " w " .. items .. " items" )
					_print( t[ k ], ( ind .. "  " ), ( s + 1 ) )

				else
					if type( v ) == "string" then
						print ( ind ..  k .. " = '" .. v .. "'" )
					else
						print ( ind ..  k .. " = " .. tostring( v ) )
					end

				end
			end

		end
	end

	-- start printing process
	_print( table, indent, step + 1 )

end


-- http://snippets.luacode.org/snippets/Table_Slice_116
function Utils.tableSlice( values, i1, i2 )
	local res = {}
	local n = #values
	-- default values for range
	i1 = i1 or 1
	i2 = i2 or n
	if i2 < 0 then
		i2 = n + i2 + 1
	elseif i2 > n then
		i2 = n
	end
	if i1 < 1 or i1 > n then
		return {}
	end
	local k = 1
	for i = i1,i2 do
		res[k] = values[i]
		k = k + 1
	end
	return res
end


-- calculates size of table, mostly used as a dictionary
--
function Utils.tableSize( t1 )
	local size = 0
	for _,v in pairs( t1 ) do
		size = size + 1
	end
	return size
end


-- http://rosettacode.org/wiki/Knuth_shuffle#Lua
--
function Utils.shuffle( t )
	local n = #t
	while n > 1 do
		local k = math.random(n)
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end
	return t
end


-- tableLength()
-- Count the number of items in a table
-- http://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
--
-- @param t the table in which to count items
-- @return number of items in table
--
function Utils.tableLength( t )
	local count = 0
	for _, _ in pairs(t) do count = count + 1 end
	return count
end




--====================================================================--
-- Math Functions
--====================================================================--



function Utils.getUniqueRandom( include, exclude )
	--print( "Utils.getUniqueRandom" )

	include = include or {}
	if #include == 0 then return end

	exclude = exclude or {}
	local exclude_hash = {} -- used as dict
	local pruned_list = {}
	local item


	math.randomseed( os.time() )

	-- process as normal if no exclusions
	if #exclude == 0 then
		item = include[ math.random( #include ) ]

	else

		-- make a hash for quicker lookup when creating pruned list
		for _, name in ipairs( exclude ) do
			exclude_hash[ name ] = true
		end

		-- create our pruned list
		for _, name in ipairs( include ) do
			if exclude_hash[ name ] ~= true then
				table.insert( pruned_list, name )
			end
		end

		-- Sanity Check
		if #pruned_list == 0 then
			print( "WARNING: Utils.getUniqueRandom()" )
			print( "The 'exclude' list is equal to the 'include' list" )
			return nil
		end

		-- get our item
		item = pruned_list[ math.random( #pruned_list ) ]
	end

	return item
end




--====================================================================--
-- Callback Functions
--====================================================================--


-- createObjectCallback()
-- Creates a closure used to bind a method to an object. Useful for creating a custom callback.
--
-- @param object the object which has the method
-- @param method the method to call
--
function Utils.createObjectCallback( object, method )
	if object == nil or method == nil then
		error( "ERROR: missing object or method in createObjectCallback()" )
	end
	return function( ... )
		return method( object, ... )
	end
end


function Utils.getTransitionCompleteFunc( count, callback )
	local total = 0
	local func = function(...)
		total = total + 1
		if total >= count then callback(...) end
	end
	return func
end




--====================================================================--
-- Audio Functions
--====================================================================--

-- volume, channel
function Utils.getAudioChannel( opts )

	opts = opts == nil and {} or opts
	opts.volume = opts.volume == nil and 1.0 or opts.volume
	opts.channel = opts.channel == nil and 1 or opts.channel

	local ac = audio.findFreeChannel( opts.channel )
	audio.setVolume( opts.volume, { channel=ac } )

	return ac

end




--====================================================================--
-- Web Functions
--====================================================================--


-- parse_query()
-- splits an HTTP query string (eg, 'one=1&two=2' ) into its components
--
-- @param  str  string containing url-type key/value pairs
-- @returns a table with the key/value pairs
--
function Utils.parse_query( str )
	local t = {}
	if str ~= nil then
		for k, v in string.gmatch( str, "([^=&]+)=([^=&]+)") do
			t[k] = v
		end
	end
	return t
end

function Utils.create_query( tbl )
	local str = ''
	for k,v in pairs( tbl ) do
		if str ~= '' then str = str .. '&' end
		str = str .. tostring( k ) .. '=' .. url_encode( tostring(v) )
	end
	return str
end



return Utils

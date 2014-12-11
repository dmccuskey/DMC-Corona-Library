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



--====================================================================--
-- DMC Corona Library : DMC Utils
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.1.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


--====================================================================--
-- Support Functions

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
-- Configuration

local dmc_lib_data, dmc_lib_info

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_corona_boot" ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_library



--====================================================================--
-- DMC Utils
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_utils = dmc_lib_data.dmc_utils or {}

local DMC_UTILS_DEFAULTS = {
	-- none
}

local dmc_utils_data = Utils.extend( dmc_lib_data.dmc_utils, DMC_UTILS_DEFAULTS )



--====================================================================--
-- Audio Functions
--====================================================================--


-- getAudioChannel( options )
-- simplifies getting an audio channel from Corona SDK
-- automatically sets volume and channel
--
-- @params opts table: with properties: volume, channel
--
function Utils.getAudioChannel( opts )
	opts = opts or {}
	opts.volume = opts.volume == nil and 1.0 or opts.volume
	opts.channel = opts.channel == nil and 1 or opts.channel
	--==--
	local ac = audio.findFreeChannel( opts.channel )
	audio.setVolume( opts.volume, { channel=ac } )
	return ac
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
-- Date Functions
--====================================================================--


--[[

	Given a UNIX time (seconds), calculate the number of weeks, days, etc
	{ months=0, weeks=2, days=3, hours=8, minutes=35, seconds=21 }

--]]

local week_s, day_s, hour_s, min_s, sec_s
sec_s = 1
min_s = 60 * sec_s
hour_s = 60 * min_s
day_s = 24 * hour_s
week_s = 7 * day_s

-- give number and remainder
local function diff( time, divisor )
	return { math.floor( time/divisor ), ( time % divisor ) }
end
function Utils.calcTimeBreakdown( seconds, params )

	seconds = math.abs( seconds )

	params = params or {}
	params.days = params.days or true
	params.hours = params.hours or true
	params.minutes = params.minutes or true

	local result, tmp = {}, { 0, seconds }

	result.weeks = 0
	if params.weeks and tmp[2] >= week_s then
		tmp = diff( tmp[2], week_s )
		result.weeks = tmp[1]
	end

	result.days = 0
	if params.days and tmp[2] >= day_s then
		tmp = diff( tmp[2], day_s )
		result.days = tmp[1]
	end

	result.hours = 0
	if params.hours and tmp[2] >= hour_s then
		tmp = diff( tmp[2], hour_s )
		result.hours = tmp[1]
	end

	result.minutes = 0
	if params.minutes and tmp[2] >= min_s then
		tmp = diff( tmp[2], min_s )
		result.minutes = tmp[1]
	end
	result.seconds = tmp[2]

	return result

end



--====================================================================--
-- Image Functions
--====================================================================--


-- imageScale()
-- container, image - table with width/height keys
-- returns scale
-- param.bind : 'inside', 'outside'
function Utils.imageScale( container, image, params )
	params = params or {}
	if params.bind == nil then params.bind = 'outside' end
	--==--

	local bind = params.bind

	local box_ratio, img_ratio
	local scale = 1

	box_ratio = container.width / container.height
	img_ratio = image.width / image.height

	if ( bind=='outside' and img_ratio > box_ratio ) or ( bind=='inside' and img_ratio < box_ratio ) then
		-- constrained by height
		scale = container.height / image.height
	else
		-- constrained by width
		scale = container.width / image.width
	end

	return scale
end



--====================================================================--
-- JSON/Lua Functions
--====================================================================--


--[[
These functions fix the issue that arises when working with JSON and
the duality of tables/arrays in Lua.
When encoding Lua structures to JSON, empty tables will be converted
to empty arrays ( {} => [] )

This is an issue for data correctness and certain Internet protocols (WAMP)
--]]

-- encodeLuaTable( table )
-- checks table structure. if empty, it will embellish it with data
-- besure to call encodeLuaTable() after it has been encoded
--
-- @params table_ref table reference to table structure
--
function Utils.encodeLuaTable( table_ref )
	-- print( "Utils.encodeLuaTable", table_ref )
	if table_ref == nil then return table_ref end
	if Utils.tableSize( table_ref ) == 0 then
		table_ref = { ['__HACK__']='__PAD__' }
	end
	return table_ref
end

-- decodeLuaTable( encoded_json )
-- removes any data embellishments added with encodeLuaTable().
--
-- @params encoded_json string of encoded JSON
--
function Utils.decodeLuaTable( encoded_json )
	-- print( "Utils.decodeLuaTable", encoded_json )
	return string.gsub( encoded_json, '"__HACK__":"__PAD__"', '' )
end


--[[
These functions fix the issue that arises when working with JSON and
the large numbers in Lua.
Large Lua numbers (integers) will always be represented by exponential notation
435985071997801 => 4.359850719978e+14

This is an issue for data correctness and certain Internet protocols (WAMP)
--]]

-- encodeLuaInteger( integer )
-- will encode the integer into a string
--
-- @params integer large integer number
--
function Utils.encodeLuaInteger( integer )
	-- print( "Utils.encodeLuaInteger", integer )
	assert( type(integer) == 'number', "encodeLuaInteger: not a number" )
	return string.format("<<<%.0f>>>", integer )
end

-- decodeLuaInteger( integer )
-- will remove encoding from encodeLuaInteger()
--
-- @params integer large integer number
--
function Utils.decodeLuaInteger( encoded_json )
	-- print( "Utils.decodeLuaTable", encoded_json )
	return string.gsub( encoded_json, '"<<<(.-)>>>"', '%1' )
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
-- String Functions
--====================================================================--


-- split string up in parts, using separator
-- returns array of pieces
function Utils.split( str, sep )
	if sep == nil then
		sep = "%s"
	end
	t={} ; i=1
	for str in string.gmatch( str, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end


-- stringFormatting()
-- implement Python-style string replacement
-- http://lua-users.org/wiki/StringInterpolation
--
function Utils.stringFormatting( a, b )
	if not b then
		return a
	elseif type(b) == "table" then
		return string.format(a, unpack(b))
	else
		return string.format(a, b)
	end
end



--====================================================================--
-- Table Functions
--====================================================================--


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


-- searches for item in table (as array), removes and returns item
--
function Utils.removeFromTable( t, item )
	local o = nil
	for i=#t,1,-1 do
		if t[i] == item then
			o = table.remove( t, i )
			break
		end
	end
	return o
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


-- calculates size of table, mostly used as a dictionary
--
function Utils.tableSize( t1 )
	local size = 0
	for _,v in pairs( t1 ) do
		size = size + 1
	end
	return size
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
-- Web Functions
--====================================================================--

function Utils.is_iOS()
	if string.sub(system.getInfo('model'),1,2) == "iP" then
		return true
	end
	return false
end


-- state -- 'show'/'hide'
--
function Utils.checkIsiPhone5( state, params )
	local isiPhone5 = false

	-- Check if device is iPhone 5
	if string.sub(system.getInfo("model"),1,2) == "iP" and display.pixelHeight > 960 then
		isiPhone5 = true
	end
	return isiPhone5
end


--====================================================================--
-- Status Bar Functions

Utils.STATUS_BAR_DEFAULT = display.DefaultStatusBar
Utils.STATUS_BAR_HIDDEN = display.HiddenStatusBar
Utils.STATUS_BAR_TRANSLUCENT = display.TranslucentStatusBar
Utils.STATUS_BAR_DARK = display.DarkStatusBar


function Utils.setStatusBarDefault( status )
	status = status == nil and display.DefaultStatusBar or status
	Utils.STATUS_BAR_DEFAULT = status
end


-- state -- 'show'/'hide'
--
function Utils.setStatusBar( state, params )
	params = params or {}
	if params.type == nil then params.type = Utils.STATUS_BAR_DEFAULT end
	assert( state=='show' or state=='hide', "Utils.setStatusBar: unknown state"..tostring(state) )
	--==--

	if not Utils.is_iOS() then return end

	local status

	if state == 'hide' then
		status = Utils.STATUS_BAR_HIDDEN
	else
		status = params.type
	end
	display.setStatusBar( status )

end





return Utils

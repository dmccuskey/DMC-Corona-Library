
--====================================================================--
-- dmc_utils.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_utils.lua
--====================================================================--


--[[

Copyright (C) 2011-2013 David McCuskey. All Rights Reserved.

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

local VERSION = "0.8.0"



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
-- Setup, Constants
--====================================================================--


--====================================================================--
-- Support Methods
--====================================================================--


--====================================================================--
-- Utils Module
--====================================================================--





--====================================================================--
-- Date Calculation
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
-- Map, Filter, Reduce
--====================================================================--

-- http://lua-users.org/wiki/FunctionalLibrary

 -- Functional Library
 --
 -- @file    functional.lua
 -- @author  Shimomura Ikkei
 -- @date    2005/05/18
 --
 -- @brief    porting several convenience functional utilities form Haskell,Python etc..
 -- map(function, table)
 -- e.g: map(double, {1,2,3})    -> {2,4,6}
function Utils.map(func, tbl)
		local newtbl = {}
		for i,v in pairs(tbl) do
			newtbl[i] = func(v)
		end
		return newtbl
end
 -- filter(function, table)
 -- e.g: filter(is_even, {1,2,3,4}) -> {2,4}
function Utils.filter(func, tbl)
		local newtbl= {}
		for i,v in pairs(tbl) do
			if func(v) then
				newtbl[i]=v
			end
		end
		return newtbl
 end





function Utils.split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
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


-- createObjectCallback()
-- Creates a closure used to bind a method to an object. Useful for creating a custom callback.
--
-- @param object the object which has the method
-- @param method the method to call
--
function Utils.createObjectCallback( object, method )
	if object == nil or method == nil then
		print( "WARNING: nil or missing parameter in createObjectCallback()" )
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
-- Time Marker
--====================================================================--

local firstTimeMarker = nil
local lastTimeMarker = nil
local timeMarks = {}

local function calculateTime()

end
function Utils.markTime( marker, params )
	local t = system.getTimer()
	local precision = 100000
	local delta = 0
	params = params or {}
	if params.reset == true then lastTimeMarker = nil end
	if params.print == nil then params.print = true end

	if firstTimeMarker == nil then
		print( "MARK    : ".."Application Started: ".." (T:"..tostring(t)..")" )
		firstTimeMarker = t
	end
	if lastTimeMarker == nil then lastTimeMarker = t end

	if params.print then
		delta = math.floor((t-lastTimeMarker)*precision)/precision
		print( "MARK    : "..marker, tostring(delta).." (T:"..tostring(t)..")" )
	end

	lastTimeMarker = t
	if marker then timeMarks[ marker ] = t end
end

function Utils.markTimeDiff( marker1, marker2 )
	local precision = 100000
	local t1, t2 = timeMarks[marker1], timeMarks[marker2]
	local delta = math.floor((t1-t2 )*precision)/precision

	print( "MARK <d>: ".. marker1.."<=>"..marker2.." <d> ".. tostring( math.abs(delta)) )
end




--====================================================================--
-- Memory Monitor
--====================================================================--

local memoryWatcherCallback = nil


-- Memory Monitor function

function Utils.memoryMonitor()

	collectgarbage()

	local memory = collectgarbage("count")
	local texture = system.getInfo( "textureMemoryUsed" ) / 1048576

	print( "M: " .. memory, " T: " .. texture )

end


-- watchMemory()
-- prints out current memory values
--
-- value (boolean:
-- if true, start memory watching every frame
-- if false, stop current memory watching
-- if number, start memory watching every Number of milliseconds
--
function Utils.watchMemory( value )

	local f

	if value == true then
		-- setup constant, frame rate memory watch

		Runtime:addEventListener( "enterFrame", Utils.memoryMonitor )

		memoryWatcherCallback = function()
			Runtime:removeEventListener( "enterFrame", Utils.memoryMonitor )
			memoryWatcherCallback = nil
		end

	elseif type( value ) == "number" and value > 0 then

		local timer = timer.performWithDelay( value, Utils.memoryMonitor, 0 )

		memoryWatcherCallback = function()
			timer.cancel( timer )
			memoryWatcherCallback = nil
		end

	elseif value == false and memoryWatcherCallback ~= nil then
		-- stop watching memory
		memoryWatcherCallback()
	end

end




return Utils

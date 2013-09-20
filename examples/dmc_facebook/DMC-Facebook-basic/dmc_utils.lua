
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


local Utils = {}


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
-- @param table the table with *list* of properties
-- @param property the name of the property to search for
--
function Utils.propertyIn( table, property )

	for _, v in pairs( table ) do
		if v == property then return true end
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


--
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



function Utils.getTransitionCompleteFunc( count, callback )
	local total = 0
	local func = function( event )
		total = total + 1
		if total >= count then callback( event ) end
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

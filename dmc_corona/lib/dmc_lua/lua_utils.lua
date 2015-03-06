--====================================================================--
-- lua_utils.lua
--
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_utils.lua
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014 David McCuskey

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
--== DMC Lua Library : Lua Utils
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.0"



--====================================================================--
--== Setup, Constants


local slower = string.lower

local tconcat = table.concat
local tinsert = table.insert


local Utils = {} -- Utils object



--====================================================================--
--== Callback Functions
--====================================================================--


-- createObjectCallback()
-- Creates a closure used to bind a method to an object.
-- Useful for creating a custom callback.
--
-- @param object the object which has the method
-- @param method the method to call
--
function Utils.createObjectCallback( object, method )
	assert( object, "dmc_utils.createObjectCallback: missing object" )
	assert( method, "dmc_utils.createObjectCallback: missing method" )
	--==--
	return function( ... )
		return method( object, ... )
	end
end


function Utils.getTransitionCompleteFunc( count, callback )
	assert( type(count)=='number', "requires number for count" )
	assert( type(callback)=='function', "requires callback function" )
	--==--
	local total = 0
	local func = function(...)
		total = total + 1
		if total >= count then callback(...) end
	end
	return func
end



--====================================================================--
--== Date Functions
--====================================================================--


--[[

	Given a UNIX time (seconds), split that duration into number of weeks, days, etc
	eg, { months=0, weeks=2, days=3, hours=8, minutes=35, seconds=21 }

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
--== Image Functions
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
--== Math Functions
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


-- hexDump()
-- pretty-print data in hex table
--
function Utils.hexDump( buf )
	for i=1,math.ceil(#buf/16) * 16 do
		if (i-1) % 16 == 0 then io.write(string.format('%08X  ', i-1)) end
		io.write( i > #buf and '   ' or string.format('%02X ', buf:byte(i)) )
		if i %  8 == 0 then io.write(' ') end
		if i % 16 == 0 then io.write( buf:sub(i-16+1, i):gsub('%c','.'), '\n' ) end
	end
end



--====================================================================--
--== String Functions
--====================================================================--


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
--== Table Functions
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

	if not fromTable or not toTable then
		error( "table can't be nil" )
	end
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


-- take objects from hashed table, make array table
--
function Utils.tableList( t )
	assert( type(t)=='table', "Utils.tableList expected table" )
	local list = {}
	for _, o in pairs( t ) do
		tinsert( list, o )
	end
	return list
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



--====================================================================--
--== Web Functions
--====================================================================--


function Utils.createHttpRequest( params )
	-- print( "Utils.createHttpRequest")
	params = params or {}
	--==--
	local http_params = params.http_params
	local req_t = {
		"%s / HTTP/1.1" % params.method,
		"Host: %s" % params.host,
	}

	if type( http_params.headers ) == 'table' then
		for k,v in pairs( http_params.headers ) do
			tinsert( req_t, #req_t+1, "%s:%s" % { k, v } )
		end
	end

	if http_params.body ~= nil then
		tinsert( req_t, #req_t+1, "" )
		tinsert( req_t, #req_t+1, http_params.body )
	end
	tinsert( req_t, #req_t+1, "\r\n" )

	return tconcat( req_t, "\r\n" )
end


function Utils.normalizeHeaders( headers, params )
	params = params or {}
	params.case = params.case or 'lower' -- camel, lower
	params.debug = params.debug ~= nil and params.debug or false
	--==--
	local h = {}
	local f
	if false and params.case == 'camel' then
		f = nil -- TODO
	else
		f = string.lower
	end

	for k,v in pairs( headers ) do
		if params.debug then print(k,v) end
		h[ f(k) ] = v
	end

	return h
end

-- http://lua-users.org/wiki/StringRecipes
function Utils.urlDecode( str )
	assert( type(str)=='string', "Utils.urlDecode: input not a string" )

	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)",
		function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

-- http://lua-users.org/wiki/StringRecipes
function Utils.urlEncode( str )
	assert( type(str)=='string', "Utils.urlEncode: input not a string" )

	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w %-%_%.%~])",
				function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
	end
	return str
end


-- parseQuery()
-- splits an HTTP query string (eg, 'one=1&two=2' ) into its components
--
-- @param  str  string containing url-type key/value pairs
-- @returns a table with the key/value pairs
--
function Utils.parseQuery( str )
	assert( type(str)=='string', "Utils.parseQuery: input not a string" )

	local t = {}
	if str ~= nil then
		for k, v in string.gmatch( str, "([^=&]+)=([^=&]+)") do
			t[k] = v
		end
	end
	return t
end

-- createQuery()
-- creates query string from table items
--
-- @param tbl table as dictionary
-- returns query string
--
function Utils.createQuery( tbl )
	assert( type(tbl)=='table', "Utils.createQuery: input not a table" )

	local encode = Utils.urlEncode
	local str = ''
	for k,v in pairs( tbl ) do
		if str ~= '' then str = str .. '&' end
		str = str .. tostring( k ) .. '=' .. encode( tostring(v) )
	end
	return str
end




return Utils

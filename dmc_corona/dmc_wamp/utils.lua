--====================================================================--
-- dmc_corona/dmc_wamp/utils.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014-2015 David McCuskey

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
--== DMC Corona Library : DMC WAMP Utils
--====================================================================--


--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== Imports


local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Setup, Constants


local mrandom = math.random

math.randomseed( os.time() )


local WUtils = {} -- Utils object



--====================================================================--
--== Support Functions


function WUtils.id()
	return mrandom(0, 10^14)
end



--====================================================================--
--== JSON/Lua Functions


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
function WUtils.encodeLuaTable( table_ref )
	-- print( "WUtils.encodeLuaTable", table_ref )
	if table_ref == nil or Utils.tableSize( table_ref ) == 0 then
		table_ref = { ['__HACK__']='__PAD__' }
	end
	return table_ref
end

-- decodeLuaTable( encoded_json )
-- removes any data embellishments added with encodeLuaTable().
--
-- @params encoded_json string of encoded JSON
--
function WUtils.decodeLuaTable( encoded_json )
	-- print( "WUtils.decodeLuaTable", encoded_json )
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
function WUtils.encodeLuaInteger( integer )
	-- print( "WUtils.encodeLuaInteger", integer )
	return string.format("<<<%.0f>>>", integer )
end

-- decodeLuaInteger( integer )
-- will remove encoding from encodeLuaInteger()
--
-- @params integer large integer number
--
function WUtils.decodeLuaInteger( encoded_json )
	-- print( "WUtils.decodeLuaTable", encoded_json )
	return string.gsub( encoded_json, '"<<<(.-)>>>"', '%1' )
end




return WUtils

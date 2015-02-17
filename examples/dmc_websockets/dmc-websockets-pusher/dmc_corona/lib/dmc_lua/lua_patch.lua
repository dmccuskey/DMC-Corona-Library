--====================================================================--
-- lua_patch.lua
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
--== DMC Lua Library : Lua Patch
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.3.0"



--====================================================================--
--== Imports


local Utils = {} -- make copying easier



--====================================================================--
--== Setup, Constants


local lua_patch_data = {
	string_format_active = false,
	table_pop_active = false
}

local PATCH_TABLE_POP = 'table-pop'
local PATCH_STRING_FORMAT = 'string-format'
local addTablePopPatch, removeTablePopPatch
local addStringFormatPatch, removeStringFormatPatch



--====================================================================--
--== Support Functions


--== Start: copy from lua_utils ==--

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

--== End: copy from lua_utils ==--



local function addLuaPatch( input )
	-- print( "Patch.addLuaPatch" )
	if type(input)=='table' then
		-- pass
	elseif type(input)=='string' then
		input = { input }
	elseif type(input)=='nil' then
		input = { PATCH_TABLE_POP, PATCH_STRING_FORMAT }
	else
		error( "Lua Patch:: unknown patch type '" .. type(input) .. "'" )
	end

	for i, patch_name in ipairs( input ) do
		if patch_name == PATCH_TABLE_POP then
			addTablePopPatch()

		elseif patch_name == PATCH_STRING_FORMAT then
			addStringFormatPatch()

		else
			error( "Lua Patch:: unknown patch name '" .. tostring( patch ) .. "'" )
		end
	end
end


local function addAllLuaPatches()
	addLuaPatch( nil )
end


local function removeLuaPatch( input )
	-- print( "Patch.removeLuaPatch", input )
	if type(input)=='table' then
		-- pass
	elseif type(input)=='string' then
		input = { input }
	elseif type(input)=='nil' then
		input = { PATCH_TABLE_POP, PATCH_STRING_FORMAT }
	else
		error( "Lua Patch:: unknown patch type '" .. type(input) .. "'" )
	end

	for i, patch_name in ipairs( input ) do
		if patch_name == PATCH_TABLE_POP then
			removeTablePopPatch()

		elseif patch_name == PATCH_STRING_FORMAT then
			removeStringFormatPatch()

		else
			error( "Lua Patch:: unknown patch name '" .. tostring( patch ) .. "'" )
		end
	end
end


local function removeAllLuaPatches()
	addAllLuaPatches( nil )
end



--====================================================================--
--== Setup Patches
--====================================================================--



--====================================================================--
--== Python-style string formatting


addStringFormatPatch = function()
	if lua_patch_data.string_format_active == false then
		print( "Lua Patch::activating patch '" .. PATCH_STRING_FORMAT .. "'" )
		getmetatable("").__mod = Utils.stringFormatting
		lua_patch_data.string_format_active = true
	end
end

removeStringFormatPatch = function()
	if lua_patch_data.string_format_active == true then
		print( "Lua Patch::deactivating patch '" .. PATCH_STRING_FORMAT .. "'" )
		getmetatable("").__mod = nil
		lua_patch_data.string_format_active = false
	end
end



--====================================================================--
--== Python-style table pop() method


-- tablePop()
--
local function tablePop( t, v )
	assert( type(t)=='table', "Patch:tablePop, expected table arg for pop()")
	assert( v, "Patch:tablePop, expected key" )
	local res = t[v]
	t[v] = nil
	return res
end

addTablePopPatch = function()
	if lua_patch_data.table_pop_active == false then
		print( "Lua Patch::activating patch '" .. PATCH_TABLE_POP .. "'" )
		table.pop = tablePop
		lua_patch_data.table_pop_active = true
	end
end

removeTablePopPatch = function()
	if lua_patch_data.table_pop_active == true then
		print( "Lua Patch::deactivating patch '" .. PATCH_TABLE_POP .. "'" )
		table.pop = nil
		lua_patch_data.table_pop_active = false
	end
end



--====================================================================--
--== Patch Facade
--====================================================================--


return {
	addPatch = addLuaPatch,
	addAllPatches=addAllLuaPatches,
	removePatch=removeLuaPatch,
	removeAllPatches=removeAllLuaPatch,
}

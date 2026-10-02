--====================================================================--
-- dmc_lua/bit.lua
--
-- a consistent method to load Lua BitOp on various systems
--
-- Documentation: https://github.com/dmccuskey/lua-bit-shim
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
--== DMC Lua Library: Bitop Shim
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.0"



--====================================================================--
--== Setup, Constants


-- each entry: module name, and a function that returns its
-- LuaBitOp-compatible table
local BITOP_LIBS = {
	{ 'plugin.bit', function( mod ) return mod end },
	-- numberlua's top level is unsigned; its 'bit' sub-table is signed,
	-- like LuaBitOp
	{ 'lib.bit.numberlua', function( mod ) return mod.bit end },
}

local BitOp, source
local errors = {}

for _, lib in ipairs( BITOP_LIBS ) do
	local name, getBitOp = lib[1], lib[2]
	local ok, mod = pcall( require, name )
	if ok then
		BitOp, source = getBitOp( mod ), name
		break
	end
	table.insert( errors, name .. ": " .. tostring( mod ) )
end

if not BitOp then
	error( "Bit module not found\n" .. table.concat( errors, "\n" ), 2 )
end



--====================================================================--
--== Bit Facade


-- a copy, so the loaded module's own table stays unchanged
local Bit = {
	__version=VERSION,
	__source=source,
}

for k, v in pairs( BitOp ) do
	Bit[k] = v
end


return Bit

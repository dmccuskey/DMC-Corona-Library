--====================================================================--
-- dmc_corona/dmc_bytearray.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-bytearray
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2015 David McCuskey

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
--== DMC Corona Library : DMC Byte Array
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona



--====================================================================--
--== DMC Byte Array
--====================================================================--



--====================================================================--
--== Imports


local ByteArray = require 'lib.dmc_lua.lua_bytearray'
local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Configuration


dmc_lib_data.dmc_bytearray = dmc_lib_data.dmc_bytearray or {}

local DMC_BYTEARRAY_DEFAULTS = {
	-- none
}

local dmc_bytearray_data = Utils.extend( dmc_lib_data.dmc_bytearray, DMC_BYTEARRAY_DEFAULTS )



--====================================================================--
--== Byte Array Class
--====================================================================--


-- set on lua-bytearray's shared class, not a copy: a copy would be a
-- second class, and isa() checks against either name would fail.
-- ByteArray.__version is lua-bytearray's version
--
ByteArray.VERSION = VERSION




return ByteArray

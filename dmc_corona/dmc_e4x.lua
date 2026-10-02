--====================================================================--
-- dmc_corona/dmc_e4x.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-e4x
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
--== DMC Corona Library : DMC E4X
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
--== DMC E4X
--====================================================================--



--====================================================================--
--== Imports


local LuaE4X = require 'lib.dmc_lua.lua_e4x'
local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Configuration


dmc_lib_data.dmc_e4x = dmc_lib_data.dmc_e4x or {}

local DMC_E4X_DEFAULTS = {
	-- none
}

local dmc_e4x_data = Utils.extend( dmc_lib_data.dmc_e4x, DMC_E4X_DEFAULTS )



--====================================================================--
--== E4X Module
--====================================================================--


-- a copy of lua-e4x's module, so VERSION isn't added to the
-- shared one, which other modules get from 'lib.dmc_lua.lua_e4x'
--
local E4X = {}
for k, v in pairs( LuaE4X ) do E4X[ k ] = v end

E4X.VERSION = VERSION




return E4X

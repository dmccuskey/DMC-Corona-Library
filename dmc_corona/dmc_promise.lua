--====================================================================--
-- dmc_corona/dmc_promise.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-promise
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
--== DMC Corona Library : DMC Promise
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
--== DMC Promise
--====================================================================--



--====================================================================--
--== Imports


local LuaPromise = require 'lib.dmc_lua.lua_promise'
local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Configuration


dmc_lib_data.dmc_promise = dmc_lib_data.dmc_promise or {}

local DMC_PROMISE_DEFAULTS = {
	-- none
}

local dmc_promise_data = Utils.extend( dmc_lib_data.dmc_promise, DMC_PROMISE_DEFAULTS )



--====================================================================--
--== Promise Module
--====================================================================--


-- a copy of lua-promise's module table, so VERSION isn't added to the
-- shared one. It holds the same classes, so isa() checks work whichever
-- name a module requires. Promise.__version is lua-promise's version
--
local Promise = {}
for k, v in pairs( LuaPromise ) do
	Promise[ k ] = v
end

Promise.VERSION = VERSION




return Promise

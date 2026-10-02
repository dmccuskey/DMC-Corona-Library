--====================================================================--
-- dmc_corona/dmc_events_mix.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-events-mixin
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
--== DMC Corona Library : DMC Events Mix
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
--== DMC Events Mix
--====================================================================--



--====================================================================--
--== Imports


local LuaEventsMix = require 'lib.dmc_lua.lua_events_mix'
local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Configuration


dmc_lib_data.dmc_events_mix = dmc_lib_data.dmc_events_mix or {}

local DMC_EVENTS_MIX_DEFAULTS = {
	-- none
}

local dmc_events_mix_data = Utils.extend( dmc_lib_data.dmc_events_mix, DMC_EVENTS_MIX_DEFAULTS )



--====================================================================--
--== Events Mix Module
--====================================================================--


-- a copy of lua-events-mixin's module, so VERSION isn't added to the
-- shared one, which other modules get from 'lib.dmc_lua.lua_events_mix'.
-- EventsMix itself is the shared mixin. EventsMixModule.__version is
-- lua-events-mixin's version
--
local EventsMixModule = {}
for k, v in pairs( LuaEventsMix ) do EventsMixModule[ k ] = v end

EventsMixModule.VERSION = VERSION




return EventsMixModule

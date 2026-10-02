--====================================================================--
-- dmc_corona/dmc_utils.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-utils
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2011-2015 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : DMC Utils
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.3.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Configuration


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
--== DMC Utils
--====================================================================--



--====================================================================--
--== Imports


local LuaUtils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Configuration


dmc_lib_data.dmc_utils = dmc_lib_data.dmc_utils or {}

local DMC_UTILS_DEFAULTS = {
	-- none
}

local dmc_utils_data = LuaUtils.extend( dmc_lib_data.dmc_utils, DMC_UTILS_DEFAULTS )



--====================================================================--
--== Utils Module
--====================================================================--


-- a copy of lua-utils' module, so the Solar2D functions aren't added
-- to the shared one, which other modules get from 'lib.dmc_lua.lua_utils'
--
local Utils = {}
for k, v in pairs( LuaUtils ) do Utils[ k ] = v end

Utils.VERSION = VERSION



--====================================================================--
--== Audio Functions
--====================================================================--


-- getAudioChannel( options )
-- finds a free audio channel and sets its volume
-- returns 0, without setting a volume, when no channel is free
-- (the volume of channel 0 is the volume of every channel)
--
-- @params opts table: with properties: volume, channel
--
function Utils.getAudioChannel( opts )
	opts = opts or {}
	local volume = opts.volume == nil and 1.0 or opts.volume
	local channel = opts.channel == nil and 1 or opts.channel
	--==--
	local ac = audio.findFreeChannel( channel )
	if ac == 0 then return 0 end
	audio.setVolume( volume, { channel=ac } )
	return ac
end



--====================================================================--
--== App Functions
--====================================================================--


-- true on iPhone and iPad, and in the Simulator with an iOS skin;
-- Apple TV is 'tvos', not iOS
--
function Utils.is_iOS()
	return system.getInfo( 'platform' ) == 'ios'
end


-- deprecated: from 2012, every current iPhone and iPad passes
--
function Utils.checkIsiPhone5()
	return Utils.is_iOS() and display.pixelHeight > 960
end


--======================================================--
-- Status Bar Functions

Utils.STATUS_BAR_DEFAULT = display.DefaultStatusBar
Utils.STATUS_BAR_HIDDEN = display.HiddenStatusBar
Utils.STATUS_BAR_TRANSLUCENT = display.TranslucentStatusBar
Utils.STATUS_BAR_DARK = display.DarkStatusBar


function Utils.setStatusBarDefault( status )
	status = status == nil and display.DefaultStatusBar or status
	Utils.STATUS_BAR_DEFAULT = status
end


-- state -- 'show'/'hide'
-- on every platform; those without a status bar ignore it
--
function Utils.setStatusBar( state, params )
	params = params or {}
	assert( state=='show' or state=='hide', "Utils.setStatusBar: unknown state "..tostring(state) )
	--==--
	if state == 'hide' then
		display.setStatusBar( Utils.STATUS_BAR_HIDDEN )
	else
		display.setStatusBar( params.type or Utils.STATUS_BAR_DEFAULT )
	end
end




return Utils

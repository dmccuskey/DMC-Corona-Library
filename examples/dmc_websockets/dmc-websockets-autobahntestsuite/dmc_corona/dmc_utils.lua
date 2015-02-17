--====================================================================--
-- dmc_corona/dmc_utils.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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

local VERSION = "1.2.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Support Functions


local Utils = {} -- make copying from lua_utils easier

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
--== imports


Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Configuration


dmc_lib_data.dmc_utils = dmc_lib_data.dmc_utils or {}

local DMC_UTILS_DEFAULTS = {
	-- none
}

local dmc_utils_data = Utils.extend( dmc_lib_data.dmc_utils, DMC_UTILS_DEFAULTS )



--====================================================================--
--== Audio Functions
--====================================================================--


-- getAudioChannel( options )
-- simplifies getting an audio channel from Corona SDK
-- automatically sets volume and channel
--
-- @params opts table: with properties: volume, channel
--
function Utils.getAudioChannel( opts )
	opts = opts or {}
	opts.volume = opts.volume == nil and 1.0 or opts.volume
	opts.channel = opts.channel == nil and 1 or opts.channel
	--==--
	local ac = audio.findFreeChannel( opts.channel )
	audio.setVolume( opts.volume, { channel=ac } )
	return ac
end



--====================================================================--
--== App Functions
--====================================================================--


function Utils.is_iOS()
	if string.sub(system.getInfo('model'),1,2) == "iP" then
		return true
	end
	return false
end


function Utils.checkIsiPhone5( state, params )
	local isiPhone5 = false

	-- Check if device is iPhone 5
	if string.sub(system.getInfo('model'),1,2) == "iP" and display.pixelHeight > 960 then
		isiPhone5 = true
	end
	return isiPhone5
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
--
function Utils.setStatusBar( state, params )
	params = params or {}
	params.type = params.type or Utils.STATUS_BAR_DEFAULT
	assert( state=='show' or state=='hide', "Utils.setStatusBar: unknown state "..tostring(state) )
	--==--

	if not Utils.is_iOS() then return end

	local status

	if state == 'hide' then
		status = Utils.STATUS_BAR_HIDDEN
	else
		status = params.type
	end
	display.setStatusBar( status )

end





return Utils

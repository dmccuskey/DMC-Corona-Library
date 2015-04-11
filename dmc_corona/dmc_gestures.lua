--===================================================================--
-- dmc_corona/dmc_gestures.lua
--
-- Documentation: http://docs.davidmccuskey.com/dmc-gestures
--===================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2012-2015 David McCuskey. All Rights Reserved.

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

--- A Lua module which creates Gesture Recognizers.
-- @module dmc-gestures
-- @usage local Gesture = require 'dmc_gestures'
-- local view = display.newRect( 100, 100, 200, 200 )
-- local g = Gesture.newPanGesture( view )
-- g:addEventListener( g.EVENT, gHandler )


--====================================================================--
--== DMC Corona Library : Gestures
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.0.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Support Functions


local Utils = {} -- make copying from dmc_utils easier

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
--== DMC Gesture
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_gesture = dmc_lib_data.dmc_gesture or {}

local DMC_GESTURE_DEFAULTS = {
	debug_active=false,
}

local dmc_gesture_data = Utils.extend( dmc_lib_data.dmc_gesture, DMC_GESTURE_DEFAULTS )



--====================================================================--
--== Imports


local GestureMgr = require 'dmc_gestures.gesture_manager'
local TouchMgr = require 'dmc_touchmanager'



--====================================================================--
--== Gesture Interface
--====================================================================--


local Gesture = {}


--[[
keyed on View
<view Oxjkfdjf> = <Gesture Mananger>
--]]
Gesture._GESTURE_MGR = {}



--====================================================================--
--== Gesture Static Functions


function Gesture.initialize( manager, params )
	-- print( "Gesture.initialize", manager )
	params = params or {}
	if params.mode==nil then params.mode=uiConst.RUN_MODE end
	--==--


end



--====================================================================--
--== Gesture Public Functions


--======================================================--
-- newLongPressGesture Support

function Gesture._loadLongPressGestureSupport( params )
	-- print( "Gesture._loadLongPressGestureSupport" )
	if Gesture.LongPress then return end
	--==--
	local LongPress = require 'dmc_gestures.longpress_gesture'
	Gesture.LongPress=LongPress
end

---

--- Optional parameters for newLongPressGesture()
-- @string id a name for the gesture, available in events
-- @object delegate a delegate object to control this gesture
-- @int touches minimum number of taps, default 1
-- @int max_touches maximum number of taps, default 1
-- @int threshold movement required to recognize the tap, default 10
-- @table newLongPressParams


--- Create a Long Press Gesture Recognizer.
-- creates recognizers which watch for drag/pan gestures
--
-- @object view Corona Display object
-- @tparam[opt] table params @{newLongPressParams}
-- @treturn @{Widget.LongPress} a long-press gesture object
-- @usage local g = Gesture.newLongPressGesture( view )
--
function Gesture.newLongPressGesture( view, params )
	-- print( "Gesture.newLongPressGesture", view )
	params = params or {}
	params.view = view
	--==--
	if not Gesture.LongPress then Gesture._loadLongPressGestureSupport() end
	local o = Gesture.LongPress:new( params )
	Gesture._addGestureToManager( o )
	return o
end


--======================================================--
-- newPanGesture Support

function Gesture._loadPanGestureSupport( params )
	-- print( "Gesture._loadPanGestureSupport" )
	if Gesture.Pan then return end
	--==--
	local PanGesture = require 'dmc_gestures.pan_gesture'
	Gesture.Pan=PanGesture
end

---

--- Optional parameters for newPanGesture()
-- @string id a name for the gesture, available in events
-- @object delegate a delegate object to control this gesture
-- @int touches minimum number of taps, default 1
-- @int max_touches maximum number of taps, default 1
-- @int threshold movement required to recognize the tap, default 10
-- @table newPanParams


--- Create a Pan Gesture Recognizer.
-- creates recognizers which watch for drag/pan gestures
--
-- @object view Corona Display object
-- @tparam[opt] table params @{newPanParams}
-- @treturn PanGesture a pan gesture object
-- @usage local g = Gesture.newPanGesture( view )
--
function Gesture.newPanGesture( view, params )
	-- print( "Gesture.newPanGesture", view )
	params = params or {}
	params.view = view
	--==--
	if not Gesture.Pan then Gesture._loadPanGestureSupport() end
	local o = Gesture.Pan:new( params )
	Gesture._addGestureToManager( o )
	return o
end


--======================================================--
-- newPinchGesture Support

function Gesture._loadPinchGestureSupport( params )
	-- print( "Gesture._loadPinchGestureSupport" )
	if Gesture.Pinch then return end
	--==--
	local newPinchGesture = require 'dmc_gestures.pinch_gesture'
	Gesture.Pinch=newPinchGesture
end


--- Optional parameters for newPinchGesture()
-- @string id a name for the gesture, available in events
-- @object delegate a delegate object to control this gesture
-- @bool reset_scale reset scale to 1.0 after pinch, default true
-- @int threshold touch movement required to recognize the gesture, default 5
-- @int time_limit max time allowed to recognize the gesture, default 500ms
-- @table newPinchParams


--- Create a Pinch Gesture Recognizer.
-- creates recognizers which watch for pinch gestures, eg for zoom
--
-- @object view Corona Display object
-- @tparam[opt] table params @{newPinchParams}
-- @treturn PinchGesture a pan gesture object
-- @usage local g = Gesture.newPinchGesture( view )
--
function Gesture.newPinchGesture( view, params )
	-- print( "Gesture.newPinchGesture", view )
	params = params or {}
	params.view = view
	--==--
	if not Gesture.Pinch then Gesture._loadPinchGestureSupport() end
	local o = Gesture.Pinch:new( params )
	Gesture._addGestureToManager( o )
	return o
end


--======================================================--
-- newTapGesture Support

function Gesture._loadTapGestureSupport( params )
	-- print( "Gesture._loadTapGestureSupport" )
	if Gesture.Tap then return end
	--==--
	local TapGesture = require 'dmc_gestures.tap_gesture'
	Gesture.Tap=TapGesture
end

--- Optional parameters for newTapGesture()
-- @string id a name for the gesture, available in events
-- @object delegate a delegate object to control this gesture
-- @int accuracy the maximum movement allowed between taps, default 10
-- @int taps the minimum number of taps required, default 1
-- @int time maximum time between taps, default 300 ms
-- @int touches minimum number of touches required, default 1
-- @table newTapParams

--- Create a Tap Gesture Recognizer.
-- creates recognizers which watch for tap-type gestures
--
-- @object view Corona Display object
-- @tparam[opt] table params @{newTapParams}
-- @treturn TapGesture a tap gesture object
-- @usage local g = Gesture.newTapGesture( view )
--
function Gesture.newTapGesture( view, params )
	-- print( "Gesture.newTapGesture", view )
	params = params or {}
	params.view = view
	--==--
	if not Gesture.Tap then Gesture._loadTapGestureSupport() end
	local o = Gesture.Tap:new( params )
	Gesture._addGestureToManager( o )
	return o
end



--====================================================================--
--== Private Functions


function Gesture._addGestureToManager( gesture )
	-- print( "Gesture._addGestureToManager", gesture, gesture.view )
	local g_mgr = Gesture._addGestureManager( gesture.view )
	g_mgr:addGesture( gesture )
	return g_mgr
end


function Gesture._addGestureManager( view )
	-- print( "Gesture._addGestureManager", view )
	assert( view )
	--==--
	local o = Gesture._getGestureManager( view )
	if not o then
		o = GestureMgr:new{ view=view }
		Gesture._GESTURE_MGR[ view ] = o
		TouchMgr.registerGestureMgr( o )
	end
	return o
end

function Gesture._getGestureManager( view )
	assert( view )
	--==--
	return Gesture._GESTURE_MGR[ view ]
end

function Gesture._removeGestureManager( view )
	assert( view )
	local o = Gesture._getGestureManager( view )
	if not o then
		Gesture._GESTURE_MGR[ view ] = nil
		o:removeSelf()
	end
end




--====================================================================--
--== Event Handlers


-- none




return Gesture

--===================================================================--
-- dmc_corona/dmc_touchmanager.lua
--
-- Documentation: http://docs.davidmccuskey.com/dmc-touchmanager
--===================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2013-2015 David McCuskey

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


--- Touch Manager Module
-- @module TouchManager
-- @usage
-- local TouchMgr = require 'dmc_corona.dmc_touchmanager'
-- local o = createDisplayObject( color )
-- TouchMgr.register( o )


--====================================================================--
--== DMC Corona Library : Touch Manager
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
--== DMC Touch Manager
--====================================================================--


--[[
Overview of Data Objects

Touch Object (t_obj)
a Corona object which can get touch events

Gesture Manager (g_mgr)
An object which coordinates one or many Gesture Receivers

--]]



--====================================================================--
--== Configuration


dmc_lib_data.dmc_touchmanager = dmc_lib_data.dmc_touchmanager or {}

local DMC_TOUCHMANAGER_DEFAULTS = {
	default_color_format='dRGBA',
	-- named_color_file, no default,
}

local dmc_touchmanager_data = Utils.extend( dmc_lib_data.dmc_touchmanager, DMC_TOUCHMANAGER_DEFAULTS )



--====================================================================--
--== Imports


-- none



--====================================================================--
--== Setup, Constants


system.activate( 'multitouch' )

local tinsert = table.insert
local tremove = table.remove



--====================================================================--
--== Support Functions


-- createMasterTouchHandler()
-- creates touch handler for objects
-- @param master_data reference to the Touch Manager data object
--
local function createMasterTouchHandler( master_data )

	return function( event )
		-- print( "Touch Manager handler", event.phase, event.id )
		local target = event.target
		local phase = event.phase
		local response = false

		--== Get data structure for Touch Object

		local t_obj = master_data.focus[ event.id ]
		if t_obj then
			event.target = t_obj
			event.isFocused = true
		else
			t_obj = target
			event.isFocused = false
		end

		if not t_obj then return false end

		local struct = master_data.object[ t_obj ]

		if not struct then return false end

		--== Data refs from Touch Structure

		local g_mgr = struct.g_mgr

		--== Gesture Manager processes Event first

		if g_mgr then
			g_mgr:touch( event )
			response = true -- for Corona
		end

		--== Send event to other listeners

		if phase=='began' then

			if g_mgr and g_mgr.shouldDelayBeganTouches then
				-- pass, TODO
			else
				if struct:dispatch( event ) then response=true end
			end

		elseif phase=='moved' then

			if g_mgr and g_mgr.shouldDelayBeganTouches then
				-- pass, TODO
			else
				if struct:dispatch( event ) then response=true end
			end


		elseif phase=='ended' or phase=='cancelled' then

			if g_mgr and g_mgr.shouldDelayEndedTouches then
				-- pass, TODO
			else
				if struct:dispatch( event ) then response=true end
			end
		end

		return response
	end -- handler func

end



-- structure used for each Display Object
-- registered with the Touch Manager
--
local function createTouchStructure( t_obj )
	-- assert( t_obj )
	return {
		--[[
		Touch Object
		--]]
		t_obj = t_obj,

		--[[
		Gesture Manager assigned to this Touch Object
		--]]
		g_mgr = nil,

		--[[
		.listener
		a table of objects/functions interested in Touch Events
		for this display object
		key and value is the handler item itself
		}
		--]]
		listener = {},

		--[[
		these store delayed Touch Events, if g_mgr says to delay
		@TODO
		--]]
		t_began = {},
		t_moved = {},
		t_ended = {},

		_killActiveEvents=function( self, handler, active )
			-- assert( handler and active )
			local isFunc = (type(handler)=='function')
			-- create dummy event to end touch
			local evt = {
				name='touch',
				phase='ended',
				isFocused=true,
				target=self.t_obj,
				xStart=0,
				yStart=0,
				x=0,
				y=0
			}
			for _, id in ipairs( active ) do
				evt.id = id
				if isFunc then
					handler( evt )
				else
					handler:touch( evt )
				end
			end
		end,

		dispatch=function( self, event )
			-- assert( event )
			local response = false
			for _, handler in pairs( self.listener ) do
				if type(handler)=='function' then
					if handler( event ) then response=true end
				else
					if handler:touch( event ) then response=true end
				end
			end
			return response
		end,

		addListener=function( self, handler )
			-- assert( handler )
			self.listener[ handler ] = handler
		end,

		removeListener=function( self, handler, active )
			-- assert( handler )
			local h = self.listener[ handler ]
			assert( handler==h, "handlers to not match" )
			self.listener[ handler ] = nil
			if #active>0 then
				self:_killActiveEvents( handler, active )
			end
			return handler
		end
	}

end


-- initialize the Touch Manager module
--
local function initialize( manager )
	-- print( "TouchMgr.initialize", manager )

	local handler = createMasterTouchHandler( manager._DATA )
	manager._HANDLER = handler

	-- Touch Manager listens to Global (Runtime) touch events
	-- for those that "fall through", ie handled by another object
	--
	Runtime:addEventListener( 'touch', handler )

end



--====================================================================--
--== Touch Manager Object
--====================================================================--


local TouchMgr = {}

--== Constants ==--

-- value is Master Touch Event handler
TouchMgr._HANDLER = nil

-- holds IDs of objects which have asked for focus
-- for a particular event
TouchMgr._OBJECT = {}


-- holds object which has asked for focus on a particular event
-- keyed by event id
TouchMgr._FOCUS = {}

TouchMgr._DATA = {
	object = TouchMgr._OBJECT,
	focus = TouchMgr._FOCUS,
}



--====================================================================--
--== Public Functions


--======================================================--
-- Gesture Manager

-- registerGestureMgr()
--
-- stores Gesture Manager which handles Touch Events
-- for a particular Touch Object
--
-- @param g_mgr a Gesture Manager
--
function TouchMgr.registerGestureMgr( g_mgr )
	TouchMgr._setRegisteredManager( g_mgr )
end


-- unregisterGestureMgr()
--
-- removes Gesture Manager which handles Touch Events
-- for a particular Touch Object
--
-- @param g_mgr a Gesture Manager
--
function TouchMgr.unregisterGestureMgr( g_mgr )
	local r = TouchMgr._getRegisteredObject( g_mgr )
		if r then
			TouchMgr._setRegisteredObject( obj, nil )
			obj:removeEventListener( 'touch', r.callback )
		end
end



--======================================================--
-- Client Handler

--- register a Display Object and handler.
--  puts Touch Manager in control of touch events for this object.
--
-- @object t_obj a Corona-type object
-- @param[opt] handler the function or object to handle 'touch' events. if missing, will default to t_obj
--
function TouchMgr.register( t_obj, handler )
	assert( t_obj, "ERROR: TouchMgr.register missing touch object parameter" )
	if handler==nil then handler=t_obj end
	--==--
	local struct = TouchMgr._getRegisteredObjectStruct( t_obj )
	struct:addListener( handler )
end

--- unregister a Display Object and handler.
-- removes Touch Manager control of touch events for this object.
--
-- @param t_obj a Corona-type object
-- @param[opt] handler the function or object to handle 'touch' events. if missing, will default to t_obj
--
function TouchMgr.unregister( t_obj, handler )
	assert( t_obj, "ERROR: TouchMgr.unregister missing touch object parameter" )
	if handler==nil then handler=t_obj end
	--==--
	local struct = TouchMgr._getRegisteredObjectStruct( t_obj )
	local active = TouchMgr._getActiveTouches( t_obj )
	struct:removeListener( handler, active )
	TouchMgr._removeRegisteredObjectStruct( t_obj )
end


--- sets focus on an object for a single touch event.
-- ensures touch event is locked to this touch object.
--
-- @object t_obj a Corona-type object
-- @param event_id id of the touch event
--
function TouchMgr.setFocus( t_obj, event_id )
	assert( t_obj, "ERROR: TouchMgr.setFocus missing touch object parameter" )
	assert( event_id, "ERROR: TouchMgr.setFocus missing event id parameter" )
	--==--
	-- print( "TouchMgr.setFocus", t_obj )
	TouchMgr._setRegisteredTouch( event_id, t_obj )
end

--- removes focus on an object for a single touch.
-- removes touch event lock on this touch object.
--
-- @object t_obj a Corona-type object
-- @param event_id id of the touch event
--
function TouchMgr.unsetFocus( t_obj, event_id )
	assert( t_obj, "ERROR: TouchMgr.unsetFocus missing touch object parameter" )
	assert( event_id, "ERROR: TouchMgr.unsetFocus missing event id parameter" )
	--==--
	local o = TouchMgr._unsetRegisteredTouch( event_id )
end



--====================================================================--
--== Private Functions


--======================================================--
-- Registered Touch Objects

-- will not complain if one already exists
-- will just hand that one back
--
function TouchMgr._getRegisteredObjectStruct( t_obj )
	local struct = TouchMgr._OBJECT[ t_obj ]
	if not struct then
		struct = createTouchStructure( t_obj )
		TouchMgr._OBJECT[ t_obj ] = struct
		t_obj:addEventListener( 'touch', TouchMgr._HANDLER )
	end
	return struct
end

-- remove touch struct
-- only removes if there are no listeners
--
function TouchMgr._removeRegisteredObjectStruct( t_obj )
	local struct = TouchMgr._OBJECT[ t_obj ]
	if not struct then return end
	local cnt = 0
	for _, __ in pairs( struct.listener ) do
		cnt=cnt+1
		-- print(_, __)
	end
	if cnt==0 then
		t_obj:removeEventListener( 'touch', TouchMgr._HANDLER )
		TouchMgr._OBJECT[ t_obj ] = nil
	end
	return struct
end


--======================================================--
-- Registered Gesture Managers

function TouchMgr._getRegisteredManager( t_obj )
	-- assert( t_obj )
	local struct = TouchMgr._getTouchStructure( t_obj )
	return struct.g_mgr
end

function TouchMgr._setRegisteredManager( g_mgr )
	-- assert( g_mgr and g_mgr.view )
	local struct = TouchMgr._getRegisteredObjectStruct( g_mgr.view )
	assert( struct.g_mgr==nil )
	g_mgr.touch_manager = TouchMgr
	struct.g_mgr = g_mgr
end


--======================================================--
-- Active Registered Touches

function TouchMgr._getActiveTouches( t_obj )
	local list = {}
	for te_id, value in pairs( TouchMgr._FOCUS ) do
		if t_obj==value then
			tinsert( list, te_id )
		end
	end
	return list
end


function TouchMgr._getRegisteredTouch( event_id )
	-- assert( event_id )
	return TouchMgr._FOCUS[ event_id ]
end

function TouchMgr._setRegisteredTouch( event_id, t_obj )
	-- assert( event_id and t_obj )
	TouchMgr._FOCUS[ event_id ] = t_obj
end

function TouchMgr._unsetRegisteredTouch( event_id )
	-- assert( event_id )
	local o = TouchMgr._FOCUS[ event_id ]
	TouchMgr._FOCUS[ event_id ] = nil
	return o
end




--====================================================================--
--== Initial Touch Manager Setup


initialize( TouchMgr )



return TouchMgr

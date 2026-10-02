--===================================================================--
-- dmc_corona/dmc_touchmanager.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-touchmanager
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


--- A Lua module to patch multitouch in Corona SDK.
--
-- @module dmc-touchmanager
--
-- @usage
-- local TouchMgr = require 'dmc_touchmanager'
-- local o = createDisplayObject( color )
-- TouchMgr.register( o )


--====================================================================--
--== DMC Corona Library : Touch Manager
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.1.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Configuration


-- boot dmc_corona with boot script, if it's there
-- dmc-touchmanager has no settings
--
pcall( function() require( 'dmc_corona_boot' ) end )



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
--== Imports


-- none



--====================================================================--
--== Setup, Constants


system.activate( 'multitouch' )

local tinsert = table.insert
local tremove = table.remove



--====================================================================--
--== Support Functions


-- dispatchToStruct()
-- sends a touch event to the gesture manager and handlers of a
-- Touch Object
-- @return true if the event was handled
--
local function dispatchToStruct( struct, event )
	local response = false

	--== Gesture Manager processes Event first

	local g_mgr = struct.g_mgr
	if g_mgr then
		g_mgr:touch( event )
		response = true -- for Corona
	end

	--== Send event to other listeners

	if struct:dispatch( event ) then response=true end

	return response
end


-- createMasterTouchHandlers()
-- creates touch handlers for objects and for Runtime
-- @param master_data reference to the Touch Manager data object
--
local function createMasterTouchHandlers( master_data )

	-- recordPosition()
	-- keeps the last position of a focused touch, for the
	-- event unregister() makes up
	--
	local function recordPosition( event )
		local id = event.id
		if master_data.focus[ id ] then
			master_data.position[ id ] = {
				x=event.x, y=event.y,
				xStart=event.xStart, yStart=event.yStart
			}
		end
	end

	-- a focused touch goes to the object which holds it,
	-- wherever it arrives; it counts as handled
	--
	local function dispatchFocused( event, t_obj )
		local struct = master_data.object[ t_obj ]
		if not struct then return false end
		event.target = t_obj
		event.isFocused = true
		dispatchToStruct( struct, event )
		recordPosition( event )
		return true
	end

	local function objectHandler( event )
		-- print( "Touch Manager handler", event.phase, event.id )
		local t_obj = master_data.focus[ event.id ]
		if t_obj then return dispatchFocused( event, t_obj ) end

		t_obj = event.target
		local struct = t_obj and master_data.object[ t_obj ]
		if not struct then return false end

		event.isFocused = false
		local response = dispatchToStruct( struct, event )
		-- a handler may have set focus, in 'began': then it's
		-- handled, or Runtime would send it to the object again
		if master_data.focus[ event.id ] then
			recordPosition( event )
			response = true
		end
		return response
	end

	-- Runtime gets the touches no object handled:
	-- only focused ones are of interest
	--
	local function runtimeHandler( event )
		local t_obj = master_data.focus[ event.id ]
		if not t_obj then return false end
		return dispatchFocused( event, t_obj )
	end

	return objectHandler, runtimeHandler
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
		a list of objects/functions interested in Touch Events
		for this display object, in the order they were registered
		--]]
		listener = {},

		--[[
		.finalize
		the object's 'finalize' listener, which forgets the object
		when it's removed
		--]]
		finalize = nil,

		_killActiveEvents=function( self, handler, active, position )
			-- assert( handler and active )
			local isFunc = (type(handler)=='function')
			for _, id in ipairs( active ) do
				-- create dummy event to end touch
				local pos = position[ id ] or {}
				local evt = {
					name='touch',
					phase='cancelled',
					id=id,
					isFocused=true,
					target=self.t_obj,
					xStart=pos.xStart or 0,
					yStart=pos.yStart or 0,
					x=pos.x or 0,
					y=pos.y or 0
				}
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
			-- copy, a handler may unregister during the dispatch
			local list = {}
			for i, handler in ipairs( self.listener ) do list[ i ] = handler end
			for _, handler in ipairs( list ) do
				if type(handler)=='function' then
					if handler( event ) then response=true end
				else
					if handler:touch( event ) then response=true end
				end
			end
			return response
		end,

		hasListener=function( self, handler )
			for i, h in ipairs( self.listener ) do
				if h==handler then return i end
			end
			return nil
		end,

		isUnused=function( self )
			return #self.listener==0 and self.g_mgr==nil
		end,

		addListener=function( self, handler )
			-- assert( handler )
			if self:hasListener( handler ) then return end
			tinsert( self.listener, handler )
		end,

		removeListener=function( self, handler, active, position )
			-- assert( handler )
			local idx = self:hasListener( handler )
			if not idx then return nil end
			tremove( self.listener, idx )
			if #active>0 then
				self:_killActiveEvents( handler, active, position )
			end
			return handler
		end
	}

end


-- initialize the Touch Manager module
--
local function initialize( manager )
	-- print( "TouchMgr.initialize", manager )

	local handler, runtime_handler = createMasterTouchHandlers( manager._DATA )
	manager._HANDLER = handler
	manager._RUNTIME_HANDLER = runtime_handler

	-- Touch Manager listens to Global (Runtime) touch events
	-- for those that "fall through", ie handled by another object
	--
	Runtime:addEventListener( 'touch', runtime_handler )

end



--====================================================================--
--== Touch Manager Object
--====================================================================--


local TouchMgr = {}

TouchMgr.VERSION = VERSION

--== Constants ==--

-- value is Master Touch Event handler, for objects
TouchMgr._HANDLER = nil

-- value is Master Touch Event handler, for Runtime
TouchMgr._RUNTIME_HANDLER = nil

-- holds the touch structure of each registered object
-- keyed by object
TouchMgr._OBJECT = {}


-- holds object which has asked for focus on a particular event
-- keyed by event id
TouchMgr._FOCUS = {}

-- holds the last position of each focused touch
-- keyed by event id
TouchMgr._POSITION = {}

TouchMgr._DATA = {
	object = TouchMgr._OBJECT,
	focus = TouchMgr._FOCUS,
	position = TouchMgr._POSITION,
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
	TouchMgr._removeRegisteredManager( g_mgr )
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
-- does nothing if the handler isn't registered for the object.
--
-- @param t_obj a Corona-type object
-- @param[opt] handler the function or object to handle 'touch' events. if missing, will default to t_obj
--
function TouchMgr.unregister( t_obj, handler )
	assert( t_obj, "ERROR: TouchMgr.unregister missing touch object parameter" )
	if handler==nil then handler=t_obj end
	--==--
	local struct = TouchMgr._OBJECT[ t_obj ]
	if not struct or not struct:hasListener( handler ) then return end
	local active = TouchMgr._getActiveTouches( t_obj )
	struct:removeListener( handler, active, TouchMgr._POSITION )
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
	TouchMgr._unsetRegisteredTouch( event_id )
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
		struct.finalize = function( event )
			TouchMgr._forgetObject( t_obj )
		end
		TouchMgr._OBJECT[ t_obj ] = struct
		t_obj:addEventListener( 'touch', TouchMgr._HANDLER )
		t_obj:addEventListener( 'finalize', struct.finalize )
	end
	return struct
end

-- remove touch struct
-- only removes if there are no listeners and no gesture manager;
-- then releases the object's focused touches
--
function TouchMgr._removeRegisteredObjectStruct( t_obj )
	local struct = TouchMgr._OBJECT[ t_obj ]
	if not struct then return end
	if struct:isUnused() then
		t_obj:removeEventListener( 'touch', TouchMgr._HANDLER )
		t_obj:removeEventListener( 'finalize', struct.finalize )
		TouchMgr._forgetObject( t_obj )
	end
	return struct
end

-- forget an object: its structure and focused touches
-- called for a removed object, from its 'finalize' event
--
function TouchMgr._forgetObject( t_obj )
	for _, id in ipairs( TouchMgr._getActiveTouches( t_obj ) ) do
		TouchMgr._unsetRegisteredTouch( id )
	end
	TouchMgr._OBJECT[ t_obj ] = nil
end


--======================================================--
-- Registered Gesture Managers

function TouchMgr._getRegisteredManager( t_obj )
	-- assert( t_obj )
	local struct = TouchMgr._OBJECT[ t_obj ]
	return struct and struct.g_mgr
end

function TouchMgr._setRegisteredManager( g_mgr )
	-- assert( g_mgr and g_mgr.view )
	local struct = TouchMgr._getRegisteredObjectStruct( g_mgr.view )
	if struct.g_mgr==g_mgr then return end
	assert( struct.g_mgr==nil, "ERROR: TouchMgr object already has a gesture manager" )
	g_mgr.touch_manager = TouchMgr
	struct.g_mgr = g_mgr
end

function TouchMgr._removeRegisteredManager( g_mgr )
	local struct = TouchMgr._OBJECT[ g_mgr.view ]
	if not struct or struct.g_mgr~=g_mgr then return end
	struct.g_mgr = nil
	return TouchMgr._removeRegisteredObjectStruct( g_mgr.view )
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
	TouchMgr._POSITION[ event_id ] = nil
	return o
end




--====================================================================--
--== Initial Touch Manager Setup


initialize( TouchMgr )



return TouchMgr

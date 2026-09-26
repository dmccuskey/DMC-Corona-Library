--====================================================================--
-- dmc_corona/dmc_gesture/gesture_manager.lua
--
-- Documentation: http://docs.davidmccuskey.com/dmc-gestures
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
--== DMC Corona Library : Gesture Manager
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Gesture Manager
--====================================================================--



--====================================================================--
--== Configuration



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local tinsert = table.insert
local tremove = table.remove

local Gesture = nil



--====================================================================--
--== Gesture Manager Class
--====================================================================--


local GestureMgr = newClass( ObjectBase, { name="Gesture Manager" } )


--======================================================--
-- Start: Setup DMC Objects

function GestureMgr:__init__( params )
	-- print( "GestureMgr:__init__", params )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	--== Sanity Check ==--

	assert( params.view )

	--== Create Properties ==--

	self._cancels_touches = true
	self._delay_began = false
	self._delay_ended = true

	-- hash of Gesture Recognizers
	-- keyed on object
	self._gestures = {}

	-- array of Gestures still active (Possible/Begin)
	-- gets reset
	self._active = {}

	-- count of active Touch Events
	self._touch_count = 0

	-- table to store initial Touch Events
	-- keyed on touch event id
	self._quarantine = nil

	self._test_mode = false

	-- array of touches which need to be passed
	-- along to Gesture Recognizers
	self._queue = {}

	self._enterFrameIterator = nil


	--== Object References ==--

	self.__mgr = nil

	-- reference to our touch manager
	self._touch_mgr = nil

	-- Corona Touch Object being watched
	self._view = params.view

end
--[[
function GestureMgr:__undoInit__()
	-- print( "GestureMgr:__undoInit__" )
	--==--
	self:superCall( '__undoInit__' )
end
--]]

--[[
function GestureMgr:__initComplete__()
	-- print( "GestureMgr:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
end

function GestureMgr:__undoInitComplete__()
	-- print( "GestureMgr:__undoInitComplete__" )
	--==--
	self:superCall( '__undoInitComplete__' )
end
--]]

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Static Methods

function GestureMgr.initialize( manager )
	Gesture = manager
end



--====================================================================--
--== Public Methods


function GestureMgr.__getters:view()
	return self._view
end
function GestureMgr.__setters:view( value )
	self._view = value
end


function GestureMgr.__getters:touch_manager()
	return self._touch_mgr
end
function GestureMgr.__setters:touch_manager( value )
	self._touch_mgr = value
end


function GestureMgr:addGesture( gesture )
	-- print( "GestureMgr:addGesture", gesture )
	assert( gesture )
	--==--
	self._gestures[ gesture ] = gesture
	gesture.gesture_mgr = self
	self:_resetGestures()
end

function GestureMgr:removeGesture( gesture, params )
	-- print( "GestureMgr:removeGesture", gesture )
	params = params or {}
	if params.reset==nil then params.reset=true end
	assert( gesture )
	--==--
	local gestures = self._gestures
	gestures[ gesture ] = nil
	if Utils.tableLength( gestures )==0 then
		Gesture.removeGestureManager( self )
	else
		if params.reset then self:_resetGestures() end
	end
end



--====================================================================--
--== Private Methods


-- reset gestures and move to Active table
--
function GestureMgr:_resetGestures()
	-- print( "GestureMgr:_resetGestures" )
	local active = {}
	for _, g in pairs( self._gestures ) do
		tinsert( active, g )
		g:reset()
	end
	self._active = active
end

-- check to see if Gestures need to be reset for next round
--
function GestureMgr:_verifyResetGestures( params )
	-- print( "GestureMgr:_verifyResetGestures" )
	-- print( self._touch_count>0, #self._active>0, #self._queue>0 )
	if #self._active>0 or self._touch_count>0 or #self._queue>0 then return end
	self:_resetGestures()
end


-- remove Gesture from Active Gestures.
-- Gesture will stop receiving Touch notifications
-- does not Fail
--
function GestureMgr:_removeActiveGesture( gesture )
	-- print("GestureMgr:_removeActiveGesture", gesture._id )
	local active = self._active
	for i=#active, 1, -1 do
		local g = active[i]
		if g==gesture then
			tremove( active, i )
		end
	end
end


-- Recognizing gestures get Touch Events first
--
function GestureMgr:_sortActiveGestures( gestures )
	-- print( "GestureMgr:_sortActiveGestures", #gestures )
	if #gestures==1 or #gestures==0 then return end
	for i=#gestures, 1, -1 do
		local g = gestures[i]
		local st = g:getState()
		if st==g.STATE_BEGAN or st==g.STATE_CHANGED then
			tinsert( gestures, tremove( gestures, i ) )
		end
	end
end


-- Fail remaining Gestures after getting Recognized notification.
-- forceToFail() may not fail, depending on Delegate.
-- if not Failed will stay in Active
--
-- @param gesture the Gesture which has Recognized
--
function GestureMgr:_failOtherGestures( gesture )
	-- print("GestureMgr:_failOtherGestures", gesture._id )
	local active = self._active
	for i=#active, 1, -1 do
		local g = active[i]
		if g~=gesture then
			local failed = g:forceToFail( gesture )
			if failed then
				tremove( active, i )
			end
		end
	end
end


-- gives Touch Event to remaining Active Gestures
--
function GestureMgr:_processQueue( queue, gestures )
	-- print("GestureMgr:_processQueue", #queue )
	for i=1,#queue do
		for j=#gestures, 1, -1 do
			local g = gestures[j]
			if g then g:touch( queue[i] ) end
		end
	end
end


--======================================================--
--== EnterFrame Control

function GestureMgr:_stopEnterFrame()
	local eF = self._enterFrameIterator
	if not eF then return end
	Runtime:removeEventListener( 'enterFrame', eF )
	self._enterFrameIterator = nil
end

function GestureMgr:_startEnterFrame()
	local eF = function( e )
		-- print( "GestureMgr:enterFrame" )
		local active = self._active
		local quarantine = self._quarantine
		local queue = self._queue

		self:_stopEnterFrame()

		-- process quarantine first, then queue

		if quarantine then
			self:_processQuarantine( quarantine, active )
			self._quarantine = nil -- empty quarantine
			self:_sortActiveGestures( active )
		end
		if #queue then
			self:_processQueue( queue, active )
			self._queue = {} -- empty queue
			self:_sortActiveGestures( active )
		end

		self:_verifyResetGestures()
	end

	Runtime:addEventListener( 'enterFrame', eF )
	self._enterFrameIterator = eF
end


--======================================================--
--== Quarantine Control

--[[
Quarantine is are area to put new Touch Events.

This is because the initial series of Touch Events
starting from BEGAN to MOVED can be "messy",
having coordinates which are unstable.
So to process new events:
# when we see BEGAN, collect that and following touches for a frame
# when frame is over, dump all touches except for the last
# change phase of saved touch to BEGAN
and start from there
--]]

-- @tparam table quarantine
function GestureMgr:_addToQuarantine( quarantine, touch )
	-- print("GestureMgr:_addToQuarantine", touch.phase )
	if quarantine==nil then quarantine={} end
	--==--
	quarantine[ touch.id ] = { touch }
	return quarantine
end

-- check whether Touch Event ID is already in quarantine
-- if it is, put this new Touch Event in as well
-- returns true/false, whether added to quarantine
--
function GestureMgr:_checkQuarantine( quarantine, touch )
	-- print("GestureMgr:_checkQuarantine", touch.phase )
	local isQuarantined = quarantine and quarantine[ touch.id ]
	if isQuarantined then
		tinsert( isQuarantined, touch )
	end
	return (isQuarantined~=nil)
end

-- process the groups of stored touches
-- each group gets filtered to 1 Touch Event,
-- and its phase is set to 'began'
--
function GestureMgr:_processQuarantine( quarantine, gestures )
	-- print("GestureMgr:_processQuarantine", quarantine, gestures )
	local queue = {}

	-- process quarantine touches
	for _, group in pairs( quarantine ) do
		-- get last touch event from group
		-- and change to 'began'
		local te = group[ #group ]
		local ne = {
			name=te.name,
			id=te.id,
			phase='began', -- << this is the important part
			target=te.target,
			time=te.time,
			x=te.x, y=te.y,
			xStart=te.x,
			yStart=te.y,
		}
		tinsert( queue, ne )
	end

	-- send touches to Gestures
	for i=1,#queue do
		for j=#gestures, 1, -1 do
			local g = gestures[j]
			if g:shouldReceiveTouch() then
				g:touch( queue[i] )
			else
				self:_removeActiveGesture( g )
			end
		end
	end
end


--====================================================================--
--== Event Handlers



-- gesture()
-- Gesture callback for Manager
--
function GestureMgr:gesture( event )
	-- print( "GestureMgr:gesture", event.type, event.state )
	local target = event.target
	local etype = event.type

	if etype==target.GESTURE then
		-- A Gesture recognized Touches
		self:_failOtherGestures( target )

	elseif etype==target.STATE then
		local state = event.state
		if state==target.STATE_FAILED or state==target.STATE_CANCELLED then
			-- Gesture Failed recognition
			self:_removeActiveGesture( target )
		elseif state==target.STATE_RECOGNIZED then
			self:_removeActiveGesture( target )
		end
	end

	self:_verifyResetGestures()
end


--- touch event handler.
-- Touch Events coming from Touch Manager
--
function GestureMgr:touch( event )
	-- print( "GestureMgr:touch", event.id, event.phase )
	local target = event.target
	local phase = event.phase
	local quarantine = self._quarantine
	local queue = self._queue

	if phase=='began' then
		self._touch_count=self._touch_count+1
		self._touch_mgr.setFocus( target, event.id )
		self._quarantine = self:_addToQuarantine( quarantine, event )
		if not self._enterFrameIterator then
			-- start for 'began' events
			self:_startEnterFrame()
		end
	end

	-- @TODO, check this
	if self._touch_count==0 then return end

	if phase=='moved' then
		if not quarantine or not self:_checkQuarantine( quarantine, event ) then
			tinsert( queue, event )
		end

	elseif phase=='ended' or phase=='cancelled' then
		-- if not self._test_mode or (self._test_mode and self._touch_count>1) then --- TEST
			if not quarantine or not self:_checkQuarantine( quarantine, event ) then
				tinsert( queue, event )
			end
			self._touch_mgr.unsetFocus( target, event.id )
			self._touch_count=self._touch_count-1
		-- end -- TEST
	end

	if not self._enterFrameIterator then
		-- start for 'moved', 'ended', 'cancelled' events
		self:_startEnterFrame()
	end
end




return GestureMgr


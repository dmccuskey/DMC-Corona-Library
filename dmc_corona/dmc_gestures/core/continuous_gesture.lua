--====================================================================--
-- dmc_corona/dmc_gesture/core/continous_gesture.lua
--
-- Documentation:
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
--== DMC Corona Library : Continuous Continuous Base
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Continuous Continuous
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'

local Gesture = require 'dmc_gestures.core.gesture'


--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass

local sfmt = string.format
local tinsert = table.insert
local tstr = tostring



--====================================================================--
--== Continuous Base Class
--====================================================================--


--- Continous Gesture Recognizer Base Class.
-- Base class for all Continuous Gesture Recognizers.
--
-- **Inherits from:**
--
-- * @{Gesture.Gesture}
--
-- @classmod Gesture.Continuous

local Continuous = newClass( Gesture, { name="Continuous" } )

--- Class Constants.
-- @section

--== Class Constants

Continuous.TYPE = nil -- override this

--== State Constants

Continuous.STATE_BEGAN = 'state_began'
Continuous.STATE_CHANGED = 'state_changed'
Continuous.STATE_CANCELLED = 'state_cancelled'
Continuous.STATE_SOFT_RESET = 'state_soft_reset'

--== Event Constants

--- BEGAN Event
Continuous.BEGAN = 'began'

--- CHANGED Event
Continuous.CHANGED = 'changed'

--- ENDED Event
Continuous.ENDED = 'ended'

--- RECOGNIZED Event
Continuous.RECOGNIZED = Continuous.ENDED


--======================================================--
-- Start: Setup DMC Objects

--[[
function Continuous:__init__( params )
	-- print( "Continuous:__init__", params )
	params = params or {}
	self:superCall( '__init__', params )
	--==--
	--== Create Properties ==--
end
--]]
--[[
function Continuous:__undoInit__()
	-- print( "Continuous:__undoInit__" )
	--==--
	self:superCall( '__undoInit__' )
end
--]]

--[[
function Continuous:__initComplete__()
	-- print( "Continuous:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
end
--]]

--[[
function Continuous:__undoInitComplete__()
	-- print( "Continuous:__undoInitComplete__" )
	--==--
	self:superCall( ObjectBase, '__undoInitComplete__' )
end
--]]

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


-- none



--====================================================================--
--== Private Methods


--======================================================--
-- Multitouch Event


function Continuous:_addMultitouchToQueue( phase )
	-- print("Continuous:_addMultitouchToQueue", phase, self.id )
	local me = self:_createMultitouchEvent({phase=phase})
	self._multitouch_evt = me
	tinsert( self._multitouch_queue, me )
end


-- calculate the "middle" of touch points in this gesture
-- @param table of touches
-- @return Coordinate table of coordinates

function Continuous:_calculateCentroid( touches )
	-- print("Continuous:_calculateCentroid" )
	local cnt=0
	local x,y = 0,0
	for _, te in pairs( touches ) do
		x=x+te.x ; y=y+te.y
		cnt=cnt+1
	end
	return {x=x/cnt,y=y/cnt}
end


-- this one goes to the Gesture consumer (who created gesture)
function Continuous:_createMultitouchEvent( params )
	-- print("Continuous:_createMultitouchEvent" )
	params = params or {}
	if params.phase==nil then params.phase=Continuous.BEGAN end
	if params.time==nil then params.time=system.getTimer() end
	--==--
	local pos = self:_calculateCentroid( self._touches )
	local me = {
		id=self._id,
		gesture=self.TYPE,
		phase=params.phase,
		time=params.time,
		xStart=pos.x,
		yStart=pos.y,
		x=pos.x,
		y=pos.y,
		count=self._touch_count,
		touches=self._touches
	}
	return me
end

function Continuous:_updateMultitouchEvent( me, params )
	-- print("Continuous:_updateMultitouchEvent", me, params )
	params = params or {}
	if params.phase==nil then params.phase=Continuous.CHANGED end
	if params.time==nil then params.time=system.getTimer() end
	--==--
	local pos = self:_calculateCentroid( self._touches )

	me.phase = params.phase
	me.x, me.y = pos.x, pos.y
	me.count=self._touch_count
	me.time=params.time

	return me
end

function Continuous:_endMultitouchEvent( me, params )
	-- print("Continuous:_endMultitouchEvent" )
	params = params or {}
	if params.phase==nil then params.phase=Continuous.ENDED end
	if params.time==nil then params.time=system.getTimer() end
	--==--
	local pos = self:_calculateCentroid( self._touches )

	me.phase = params.phase
	me.x, me.y = pos.x, pos.y
	me.count=self._touch_count
	me.time=params.time

	return me
end


--======================================================--
-- Event Dispatch

-- this one goes to the Gesture consumer (who created gesture)
-- actually, dispatch entire Multitouch Queue
--
function Continuous:_dispatchBeganEvent()
	-- print("Continuous:_dispatchBeganEvent" )
	local queue = self._multitouch_queue
	for i=1,#queue do
		local me = queue[i]
		self:dispatchEvent( self.GESTURE, me, {merge=true} )
	end
end

-- this one goes to the Gesture consumer (who created gesture)
function Continuous:_dispatchChangedEvent()
	-- print("Continuous:_dispatchChangedEvent" )
	local me = self._multitouch_evt
	self:_updateMultitouchEvent( me )
	self:dispatchEvent( self.GESTURE, me, {merge=true} )
end

-- this one goes to the Gesture consumer (who created gesture)
function Continuous:_dispatchRecognizedEvent()
	-- print("Continuous:_dispatchRecognizedEvent" )
	local me = self._multitouch_evt
	self:_endMultitouchEvent( me )
	self:dispatchEvent( self.GESTURE, me, {merge=true} )
end




--====================================================================--
--== Event Handlers


Continuous.touch = Gesture.touch



--====================================================================--
--== State Machine


function Continuous:state_possible( next_state, params )
	-- print( "Continuous:state_possible: >> ", next_state, self.id )

	--== Check Delegate to see if this transition is OK

	local del = self._delegate
	local f = del and del.gestureShouldBegin
	local shouldBegin = true
	if f then shouldBegin = f( self ) end
	if not shouldBegin then next_state=Continuous.STATE_FAILED end

	--== Go to next State

	if next_state == Continuous.STATE_FAILED then
		self:do_state_failed( params )

	elseif next_state == Continuous.STATE_BEGAN then
		self:do_state_began( params )

	elseif next_state == Continuous.STATE_POSSIBLE then
		self:do_state_possible( params )

	elseif next_state == Continuous.STATE_SOFT_RESET then
		self:do_state_soft_reset( params )

	else
		pwarn( sfmt( "Continuous:state_possible unknown transition '%s'", tstr( next_state )))
	end
end


--== State Began ==--

function Continuous:do_state_began( params )
	-- print( "Continuous:do_state_began", params )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--
	self:_stopAllTimers()
	self:setState( Continuous.STATE_BEGAN )
	self:_dispatchGestureNotification( params )
	self:_dispatchStateNotification( params )
	self:_dispatchBeganEvent()
end

function Continuous:state_began( next_state, params )
	-- print( "Continuous:state_began: >> ", next_state, self.id )

	if next_state == Continuous.STATE_CHANGED then
		self:do_state_changed( params )

	elseif next_state == Continuous.STATE_RECOGNIZED then
		self:do_state_recognized( params )

	elseif next_state == Continuous.STATE_SOFT_RESET then
		self:do_state_soft_reset( params )

	elseif next_state == Continuous.STATE_CANCELLED then
		self:do_state_cancelled( params )

	elseif next_state == Continuous.STATE_FAILED then
		-- for either cancelled or recognized
		self:do_state_cancelled( params )

	else
		pwarn( sfmt( "Continuous:state_began unknown transition '%s'", tstr( next_state )))
	end
end


--== State Changed ==--

function Continuous:do_state_changed( params )
	-- print( "Continuous:do_state_changed" )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--

	self:setState( Continuous.STATE_CHANGED )
	self:_dispatchStateNotification( params )
	self:_dispatchChangedEvent()
end

function Continuous:state_changed( next_state, params )
	-- print( "Continuous:state_changed: >> ", next_state, self.id )

	if next_state == Continuous.STATE_CHANGED then
		self:do_state_changed( params )

	elseif next_state == Continuous.STATE_SOFT_RESET then
		self:do_state_soft_reset( params )

	elseif next_state == Continuous.STATE_CANCELLED then
		self:do_state_cancelled( params )

	elseif next_state == Continuous.STATE_RECOGNIZED then
		self:do_state_recognized( params )

	elseif next_state == Continuous.STATE_FAILED then
		-- for either cancelled or recognized
		self:do_state_cancelled( params )

	else
		pwarn( sfmt( "Continuous:state_changed unknown transition '%s'", tstr( next_state )))
	end
end


--== State Recognized ==--

function Continuous:do_state_recognized( params )
	-- print( "Continuous:do_state_recognized", self._id )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--

	self:setState( Continuous.STATE_RECOGNIZED )
	self:_dispatchStateNotification( params )
	self:_dispatchRecognizedEvent()
end


--== State Canceled ==--

function Continuous:do_state_cancelled( params )
	-- print( "Continuous:do_state_cancelled" )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--

	self:setState( Continuous.STATE_CANCELLED )
	self:_dispatchStateNotification( params )
	self:_dispatchRecognizedEvent()

end

function Continuous:state_cancelled( next_state, params )
	-- print( "Continuous:state_cancelled: >> ", next_state, self.id )

	if next_state == Continuous.STATE_POSSIBLE then
		self:do_state_possible( params )

	else
		pwarn( sfmt( "Continuous:state_cancelled unknown transition '%s'", tstr( next_state )))
	end
end


--== State Canceled ==--

function Continuous:do_state_soft_reset( params )
	-- print( "Continuous:do_state_soft_reset" )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--
	self._multitouch_queue = {}

	self:setState( Continuous.STATE_SOFT_RESET )
	self:_dispatchStateNotification( params )
	-- end current Touch Event
	self:_dispatchRecognizedEvent()

end

function Continuous:state_soft_reset( next_state, params )
	-- print( "Continuous:state_soft_reset: >> ", next_state, self.id )

	if next_state == Continuous.STATE_POSSIBLE then
		self:do_state_possible( params )

	elseif next_state == Continuous.STATE_BEGAN then
		self:do_state_began( params )

	elseif next_state == Continuous.STATE_FAILED then
		self:do_state_failed( params )

	else
		pwarn( sfmt( "Continuous:state_soft_reset unknown transition '%s'", tstr( next_state )))
	end
end




return Continuous

--====================================================================--
-- dmc_corona/dmc_gesture/core/continous_gesture.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-gestures
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
local Constants = require 'dmc_gestures.gesture_constants'


--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass

local sfmt = string.format
local tinsert = table.insert
local tremove = table.remove
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

function Continuous:__init__( params )
	-- print( "Continuous:__init__", params )
	params = params or {}
	self:superCall( '__init__', params )
	--==--
	--== Create Properties ==--

	-- whether 'began' was sent, so 'ended' may be
	self._began_sent = false
	-- recent values, for velocity
	self._velocity_samples = {}
	self._velocity_last = { 0, 0 }
end
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


function Continuous:_do_reset()
	-- print( "Continuous:_do_reset" )
	Gesture._do_reset( self )
	self._began_sent = false
	self._velocity_samples = {}
	self._velocity_last = { 0, 0 }
end


--======================================================--
-- Multitouch Event


function Continuous:_addMultitouchToQueue( phase, time )
	-- print("Continuous:_addMultitouchToQueue", phase, self.id )
	local queue = self._multitouch_queue
	local first = queue[1]
	-- one 'began' per gesture, at the start of the queue
	if not first then
		phase = Continuous.BEGAN
	elseif phase==Continuous.BEGAN then
		phase = Continuous.CHANGED
	end
	local me = self:_createMultitouchEvent({phase=phase, time=time})
	-- every event of a gesture starts where its first did
	if first then
		me.xStart, me.yStart = first.xStart, first.yStart
	end
	self._multitouch_evt = me
	tinsert( queue, me )
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
-- Velocity

-- a sample of the gesture's values (e.g. x and y), at time;
-- one without movement isn't kept, so a gesture held still
-- before it ends has no velocity
function Continuous:_addVelocitySample( time, a, b )
	-- print("Continuous:_addVelocitySample", time, a, b )
	b = b or 0
	local samples = self._velocity_samples
	local last = samples[#samples]
	if last and last.a==a and last.b==b then return end
	tinsert( samples, { t=time, a=a, b=b } )
end

-- the change per second of the sampled values, over the
-- last VELOCITY_TIME ms of movement; none when there was no
-- movement for that long before time. Samples closer than
-- VELOCITY_MIN_TIME (touches moving in the same frame) keep
-- the last velocity
-- @return velocity of the first value, and of the second
function Continuous:_calculateVelocity( time )
	-- print("Continuous:_calculateVelocity", time )
	local samples = self._velocity_samples
	local last = samples[#samples]
	if not last or time-last.t>Constants.VELOCITY_TIME then
		self._velocity_last = { 0, 0 }
		return 0, 0
	end
	while samples[1].t<last.t-Constants.VELOCITY_TIME do
		tremove( samples, 1 )
	end
	local first = samples[1]
	local dt = last.t-first.t
	if dt<Constants.VELOCITY_MIN_TIME then
		return self._velocity_last[1], self._velocity_last[2]
	end
	dt = dt/1000
	local va, vb = ( last.a-first.a )/dt, ( last.b-first.b )/dt
	self._velocity_last = { va, vb }
	return va, vb
end

-- override: sample the event's values and set its velocity
function Continuous:_addVelocity( me )
	-- print("Continuous:_addVelocity", me )
end


--======================================================--
-- Event Dispatch

-- this one goes to the Gesture consumer (who created gesture)
-- actually, dispatch entire Multitouch Queue
--
function Continuous:_dispatchBeganEvent()
	-- print("Continuous:_dispatchBeganEvent" )
	local queue = self._multitouch_queue
	self._velocity_samples = {}
	self._velocity_last = { 0, 0 }
	self._began_sent = true
	for i=1,#queue do
		local me = queue[i]
		self:_addVelocity( me )
		self:dispatchEvent( self.GESTURE, me, {merge=true} )
	end
end

-- this one goes to the Gesture consumer (who created gesture)
function Continuous:_dispatchChangedEvent( params )
	-- print("Continuous:_dispatchChangedEvent" )
	params = params or {}
	--==--
	local me = self._multitouch_evt
	self:_updateMultitouchEvent( me, {time=params.time} )
	self:_addVelocity( me )
	self:dispatchEvent( self.GESTURE, me, {merge=true} )
end

-- this one goes to the Gesture consumer (who created gesture)
-- only a gesture which sent 'began' sends 'ended'
function Continuous:_dispatchRecognizedEvent( params )
	-- print("Continuous:_dispatchRecognizedEvent" )
	params = params or {}
	--==--
	if not self._began_sent then return end
	self._began_sent = false
	local me = self._multitouch_evt
	self:_endMultitouchEvent( me, {time=params.time} )
	self:_addVelocity( me )
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
	elseif next_state == Continuous.STATE_CANCELLED then
		-- nothing began, nothing to cancel
		self:do_state_failed( params )

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
	if #self._multitouch_queue==0 then
		self:_addMultitouchToQueue( Continuous.BEGAN, params.time )
	end
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
	self:_dispatchChangedEvent( params )
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
	self:_dispatchRecognizedEvent( params )
end


--== State Canceled ==--

function Continuous:do_state_cancelled( params )
	-- print( "Continuous:do_state_cancelled" )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--

	self:setState( Continuous.STATE_CANCELLED )
	self:_dispatchStateNotification( params )
	self:_dispatchRecognizedEvent( params )

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
	self:_dispatchRecognizedEvent( params )

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

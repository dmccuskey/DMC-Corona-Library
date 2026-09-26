--====================================================================--
-- dmc_corona/dmc_gesture/core/gesture.lua
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
--== DMC Corona Library : Gesture Base
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== DMC Gesture
--====================================================================--



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Patch = require 'dmc_patch'

local StatesMixModule = require 'dmc_states_mix'
local Constants = require 'dmc_gestures.gesture_constants'



--====================================================================--
--== Setup, Constants


Patch.addPatch( 'print-output' )

local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local StatesMix = StatesMixModule.StatesMix

local sfmt = string.format
local tcancel = timer.cancel
local tdelay = timer.performWithDelay
local tstr = tostring


--====================================================================--
--== Gesture Base Class
--====================================================================--


--- Gesture Recognizer Base Class.
-- Base class for all Gesture Recognizers.
--
-- **Inherits from:**
--
-- * DMC.ObjectBase
-- * DMC.StatesMix
--
-- @classmod Gesture.Gesture

local Gesture = newClass(
	{ ObjectBase, StatesMix }, { name="Gesture Base Class" }
)

--== Class Constants

Gesture.TYPE = nil -- override this

--== State Constants

Gesture.STATE_CREATE = 'state_create'
Gesture.STATE_POSSIBLE = 'state_possible'
Gesture.STATE_FAILED = 'state_failed'
Gesture.STATE_RECOGNIZED = 'state_recognized'

--== Event Constants

--- EVENT Name
Gesture.EVENT = 'gesture-event'

--- GESTURE Event
Gesture.GESTURE = 'recognized-gesture-event'

--- STATE Event
Gesture.STATE = 'state-changed-event'


--======================================================--
-- Start: Setup DMC Objects

function Gesture:__init__( params )
	-- print( "Gesture:__init__", params )
	params = params or {}

	self:superCall( StatesMix, '__init__', params )
	self:superCall( ObjectBase, '__init__', params )
	--==--

	--== Sanity Check ==--
	if self.is_class then return end

	assert( params.view )

	-- save params for later
	self._gr_params = params

	--== Create Properties ==--

	self._delegate = nil
	self._id = nil
	self._view = params.view

	-- internal properties

	self._fail_timer=nil

	self._gesture_attempt=false
	self._gesture_timer=nil

	self._multitouch_evt = nil
	self._multitouch_queue = {}

	self._touch_count = 0
	self._total_touch_count = 0
	self._touches = {} -- keyed on ID

	--== Objects ==--

	self._gesture_mgr = nil

	self:setState( Gesture.STATE_CREATE )
end
function Gesture:__undoInit__()
	-- print( "Gesture:__undoInit__" )
	--==--
	self:superCall( ObjectBase, '__undoInit__' )
	self:superCall( StatesMix, '__undoInit__' )
end


function Gesture:__initComplete__()
	-- print( "Gesture:__initComplete__" )
	self:superCall( ObjectBase, '__initComplete__' )
	--==--

	local tmp = self._gr_params

	--== Use Setters
	self.id = tmp.id
	self.delegate = tmp.delegate
	self.gesture_mgr = tmp.gesture_mgr

	self._gr_params = nil

	self:gotoState( Gesture.STATE_POSSIBLE )
end


function Gesture:__undoInitComplete__()
	-- print( "Gesture:__undoInitComplete__" )
	self:_stopAllTimers()
	self._gesture_mgr:removeGesture( self )
	--==--
	self:superCall( ObjectBase, '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods

--======================================================--
-- Getters/Setters

--- Getters and Setters
-- @section getters-setters


--== .id

--- the id (string).
-- this is useful to differentiate between
-- different gestures attached to the same view object
--
-- @function .id
-- @usage print( gesture.id )
-- @usage gesture.id = "myid"

function Gesture.__getters:id()
	return self._id
end
function Gesture.__setters:id( value )
	assert( value==nil or type(value)=='string' )
	self._id = value
end

--== .delegate

--- a gesture delegate (object/table)
--
-- @function .delegate
-- @usage print( gesture.delegate )
-- @usage gesture.delegate = { shouldRecognizeWith=<func> }

function Gesture.__getters:delegate()
	return self._delegate
end
function Gesture.__setters:delegate( value )
	assert( value==nil or type(value)=='table' )
	self._delegate = value
end


function Gesture.__getters:gesture_mgr()
	return self._gesture_mgr
end
function Gesture.__setters:gesture_mgr( value )
	self._gesture_mgr = value
end

--== .view

--- the target view (Display Object).
--
-- @function .view
-- @usage print( gesture.view )
-- @usage gesture.view = DisplayObject

function Gesture.__getters:view()
	return self._view
end
-- function Gesture.__setters:view( value )
-- 	self._view = value
-- end


-- @TODO
function Gesture:cancelsTouchesInView()
	-- print( "Gesture:cancelsTouchesInView" )
end

-- @TODO
function Gesture:delaysTouchesBegan()
	-- print( "Gesture:delaysTouchesBegan" )
end


-- @TODO
function Gesture:delaysTouchesEnded()
	-- print( "Gesture:delaysTouchesEnded" )
end

-- @TODO
function Gesture:requiresGestureRecognizerToFail()
	-- print( "Gesture:requiresGestureRecognizerToFail" )
end



function Gesture:ignoreTouch()
	-- print( "Gesture:ignoreTouch" )
end


function Gesture:_do_reset()
	-- print( "Gesture:_do_reset" )
	self._total_touch_count = 0
	self._touch_count = 0
	self._touches = {} -- keyed on ID
	self._multitouch_evt = nil
	self._multitouch_queue = {}
	self._gesture_attempt=false
	self:_stopAllTimers()
end

function Gesture:reset()
	-- print( "Gesture:reset" )
	self:_do_reset()
	self:gotoState( Gesture.STATE_POSSIBLE )
end

function Gesture:shouldReceiveTouch()
	-- print( "Gesture:reset" )
	local del = self._delegate
	local f = del and del.shouldReceiveTouch
	local shouldReceiveTouch = true
	if f then shouldReceiveTouch = f( self ) end
	assert( type(shouldReceiveTouch)=='boolean', "ERROR: Delegate shouldReceiveTouch, expected return type boolean")
	return shouldReceiveTouch
end


-- gesture is one which is Recognizing
--
function Gesture:forceToFail( gesture )
	-- print( "Gesture:forceToFail", gesture )
	local del = self._delegate
	local f = del and del.shouldRecognizeWith
	local shouldResume = false
	if f then shouldResume = f( del, gesture, self ) end
	assert( type(shouldResume)=='boolean', "ERROR: Delegate shouldRecognizeWith, expected return type boolean")
	if not shouldResume then
		self:gotoState( Gesture.STATE_FAILED, {notify=false} )
	end
	return (not shouldResume)
end



--====================================================================--
--== Private Methods


--======================================================--
-- Event Dispatch

-- this one goes to the Gesture Manager
function Gesture:_dispatchGestureNotification( params )
	-- print("Gesture:_dispatchGestureNotification", notify )
	local g_mgr = self._gesture_mgr
	if g_mgr and params.notify then
		g_mgr:gesture{
			target=self,
			id=self._id,
			type=Gesture.GESTURE,
			gesture=self.TYPE
		}
	end
end


-- this one goes to the Gesture Manager
function Gesture:_dispatchStateNotification( params )
	-- print("Gesture:_dispatchStateNotification" )
	params = params or {}
	local state = params.state or self:getState()
	--==--
	local g_mgr = self._gesture_mgr
	if g_mgr and params.notify then
		g_mgr:gesture{
			target=self,
			id=self._id,
			type=Gesture.STATE,
			state=state
		}
	end
end


-- this one goes to the Gesture consumer (who created gesture)
function Gesture:_dispatchRecognizedEvent( data )
	-- print("Gesture:_dispatchRecognizedEvent" )
	data = data or {}
	if data.id==nil then data.id=self._id end
	if data.gesture==nil then data.gesture=self.TYPE end
	--==--
	self:dispatchEvent( self.GESTURE, data, {merge=true} )
end


--======================================================--
-- Gesture Timers

function Gesture:_stopFailTimer()
	-- print( "Gesture:_stopFailTimer" )
	if not self._fail_timer then return end
	tcancel( self._fail_timer )
	self._fail_timer=nil
end

function Gesture:_startFailTimer( time )
	if time==nil then time=Constants.FAIL_TIMEOUT end
	--==--
	-- print( "Gesture:_startFailTimer", self )
	self:_stopFailTimer()
	local func = function()
		tdelay( 1, function()
			self:gotoState( Gesture.STATE_FAILED )
			self._fail_timer = nil
		end)
	end
	self._fail_timer = tdelay( time, func )
end


function Gesture:_stopGestureTimer()
	-- print( "Gesture:_stopGestureTimer" )
	if not self._gesture_timer then return end
	tcancel( self._gesture_timer )
	self._gesture_timer=nil
end

function Gesture:_startGestureTimer( time )
	-- print( "Gesture:_startGestureTimer", self )
	if time==nil then time=Constants.GESTURE_TIMEOUT end
	--==--
	self:_stopFailTimer()
	self:_stopGestureTimer()
	local func = function()
		tdelay( 1, function()
			self:gotoState( Gesture.STATE_FAILED )
			self._gesture_timer = nil
		end)
	end
	self._gesture_timer = tdelay( time, func )
end


function Gesture:_stopAllTimers()
	self:_stopFailTimer()
	self:_stopGestureTimer()
end


--======================================================--
-- Touch Event

function Gesture:_createTouchEvent( event )
	-- print( "Gesture:_createTouchEvent", self.id )
	self._total_touch_count = self._total_touch_count + 1
	self._touch_count = self._touch_count + 1
	self._touches[ tstr(event.id) ] = {
		id=event.id,
		name=event.name,
		target=event.target,
		isFocused=event.isFocused,
		phase=event.phase,
		xStart=event.xStart,
		yStart=event.yStart,
		x=event.x,
		y=event.y,
	}
end

function Gesture:_updateTouchEvent( event )
	-- print( "Gesture:_updateTouchEvent", self.id )
	for id, evt in pairs( self._touches ) do
		if id==tstr(event.id) then
			evt.x, evt.y = event.x, event.y
			evt.phase = event.phase
		else
			evt.phase='stationary'
		end
	end
end

function Gesture:_endTouchEvent( event )
	-- print( "Gesture:_endTouchEvent", self.id )
	self:_updateTouchEvent( event )
	self._touch_count = self._touch_count - 1
end


function Gesture:_removeTouchEvent( event )
	-- print( "Gesture:_removeTouchEvent" )
	self._touches[ tstr(event.id) ] = nil
end



--====================================================================--
--== Event Handlers


function Gesture:touch( event )
	-- print("Gesture:touch", event.phase, self.id )
	local phase = event.phase
	if phase=='began' then
		self:_createTouchEvent( event )
	elseif phase=='moved' then
		self:_updateTouchEvent( event )
	elseif phase=='cancelled' or phase=='ended' then
	self:_endTouchEvent( event )
	end
end



--====================================================================--
--== State Machine


--== State Create ==--

function Gesture:state_create( next_state, params )
	-- print( "Gesture:state_create: >> ", next_state )

	if next_state == Gesture.STATE_POSSIBLE then
		self:do_state_possible( params )
	elseif next_state == Gesture.STATE_FAILED then
		self:do_state_failed( params )
	else
		pwarn( sfmt( "Gesture:state_create unknown transition '%s'", tstr( next_state )))
	end
end


--== State Possible ==--

function Gesture:do_state_possible( params )
	-- print( "Gesture:do_state_possible" )
	self:setState( Gesture.STATE_POSSIBLE )
end

function Gesture:state_possible( next_state, params )
	-- print( "Gesture:state_possible: >> ", next_state, self.id )

	--== Check Delegate to see if this transition is OK

	local del = self._delegate
	local f = del and del.gestureShouldBegin
	local shouldBegin = true
	if f then shouldBegin = f( self ) end
	if not shouldBegin then next_state=Gesture.STATE_FAILED end

	--== Go to next State

	if next_state == Gesture.STATE_FAILED then
		self:do_state_failed( params )

	elseif next_state == Gesture.STATE_RECOGNIZED then
		self:do_state_recognized( params )

	elseif next_state == Gesture.STATE_POSSIBLE then
		self:do_state_possible( params )

	else
		pwarn( sfmt( "Gesture:state_possible unknown transition '%s'", tstr( next_state )))
	end
end


--== State Recognized ==--

function Gesture:do_state_recognized( params )
	-- print( "Gesture:do_state_recognized", self._id )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--

	self:setState( Gesture.STATE_RECOGNIZED )
	self:_dispatchGestureNotification( params )
	self:_dispatchStateNotification( params )
	self:_dispatchRecognizedEvent()
end

function Gesture:state_recognized( next_state, params )
	-- print( "Gesture:state_recognized: >> ", next_state, self.id )

	if next_state == Gesture.STATE_POSSIBLE then
		self:do_state_possible( params )

	else
		pwarn( sfmt( "Gesture:state_recognized unknown transition '%s'", tstr( next_state )))
	end
end


--== State Failed ==--

function Gesture:do_state_failed( params )
	-- print( "Gesture:do_state_failed", self._id )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--
	self:_stopAllTimers()
	self:setState( Gesture.STATE_FAILED )
	self:_dispatchStateNotification( params )
end

function Gesture:state_failed( next_state, params )
	-- print( "Gesture:state_failed: >> ", next_state, self.id )

	if next_state == Gesture.STATE_POSSIBLE then
		self:do_state_possible( params )
	elseif next_state == Gesture.STATE_FAILED then
		-- pass
	else
		pwarn( sfmt( "Gesture:state_failed unknown transition '%s'", tstr( next_state )))
	end
end




return Gesture

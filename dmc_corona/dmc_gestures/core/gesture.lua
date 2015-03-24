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
local StatesMixModule = require 'dmc_states_mix'



--====================================================================--
--== Setup, Constants


local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local StatesMix = StatesMixModule.StatesMix



--====================================================================--
--== Gesture Base Class
--====================================================================--


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

Gesture.EVENT = 'gesture-event'

Gesture.GESTURE = 'recognized-gesture-event'
Gesture.STATE = 'state-changed-event'


--======================================================--
-- Start: Setup DMC Objects

function Gesture:__init__( params )
	-- print( "Gesture:__init__", params )
	params = params or {}
	-- params.id = params.id
	-- params.delegate = params.delegate

	self:superCall( StatesMix, '__init__', params )
	self:superCall( ObjectBase, '__init__', params )
	--==--

	--== Sanity Check ==--
	if self.is_class then return end

	assert( params.view )

	--== Create Properties ==--

	self._id = params.id

	self._view = params.view

	self._delegate = params.delegate

	self._touch_count = 0
	self._total_touch_count = 0
	self._touches = {} -- keyed on ID
	self._multitouch_evt = nil

	self._gesture_mgr = params.gesture_mgr

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
	self:gotoState( Gesture.STATE_POSSIBLE )
end

--[[
function Gesture:__undoInitComplete__()
	-- print( "Gesture:__undoInitComplete__" )
	--==--
	self:superCall( ObjectBase, '__undoInitComplete__' )
end
--]]

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function Gesture.__getters:gesture_mgr()
	return self._gesture_mgr
end
function Gesture.__setters:gesture_mgr( value )
	self._gesture_mgr = value
end


function Gesture.__getters:view()
	return self._view
end
function Gesture.__setters:view( value )
	self._view = value
end


function Gesture:cancelsTouchesInView()
	-- print( "Gesture:cancelsTouchesInView" )
end

function Gesture:delaysTouchesBegan()
	-- print( "Gesture:delaysTouchesBegan" )
end


function Gesture:delaysTouchesEnded()
	-- print( "Gesture:delaysTouchesEnded" )
end

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
	return shouldReceiveTouch
end


function Gesture:forceToFail( gesture )
	-- print( "Gesture:forceToFail", gesture )
	local del = self._delegate
	local f = del and del.shouldRecognizeSimultaneously
	local shouldResume = false
	if f then shouldResume = f( self, gesture ) end
	if not shouldResume then
		self:gotoState( Gesture.STATE_FAILED, {notify=false} )
	end
	return (not shouldResume)
end



--====================================================================--
--== Private Methods


-- this one goes to the Gesture Manager
function Gesture:_dispatchGestureNotification( notify )
	-- print("Gesture:_dispatchGestureNotification", notify )
	local g_mgr = self._gesture_mgr
	if g_mgr and notify then
		g_mgr:gesture{
			target=self,
			id=self._id,
			type=Gesture.GESTURE,
			gesture=self.TYPE
		}
	end
end


-- this one goes to the Gesture Manager
function Gesture:_dispatchStateNotification( notify )
	-- print("Gesture:_dispatchStateNotification" )
	local g_mgr = self._gesture_mgr
	if g_mgr and notify then
		g_mgr:gesture{
			target=self,
			id=self._id,
			type=Gesture.STATE,
			state=self:getState()
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


function Gesture:_createTouchEvent( event )
	-- print( "Gesture:_createTouchEvent", event, self )
	self._total_touch_count = self._total_touch_count + 1
	self._touch_count = self._touch_count + 1
	self._touches[ tostring(event.id) ] = {
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
	-- print( "Gesture:_updateTouchEvent" )
	for id, evt in pairs( self._touches ) do
		if id==tostring(event.id) then
			evt.x, evt.y = event.x, event.y
			evt.phase = event.phase
		else
			evt.phase='stationary'
		end
	end
end

function Gesture:_removeTouchEvent( event )
	-- print( "Gesture:_removeTouchEvent" )
	self._touch_count = self._touch_count - 1
	self._touches[ tostring(event.id) ] = nil
end



--====================================================================--
--== Event Handlers


function Gesture:touch( event )
	-- print("Gesture:touch" )
	local phase = event.phase
	if phase=='began' then
		self:_createTouchEvent( event )
	elseif phase=='moved' then
		self:_updateTouchEvent( event )
	elseif phase=='cancelled' or phase=='ended' then
	self:_removeTouchEvent( event )
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
		print( "WARNING :: Gesture:state_create " .. tostring( next_state ) )
	end
end


--== State Possible ==--

function Gesture:do_state_possible( params )
	-- print( "Gesture:do_state_possible" )
	params = params or {}
	--==--
	self:setState( Gesture.STATE_POSSIBLE )
end

function Gesture:state_possible( next_state, params )
	-- print( "Gesture:state_possible: >> ", next_state )

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
		print( "WARNING :: Gesture:state_possible " .. tostring( next_state ) )
	end
end


--== State Recognized ==--

function Gesture:do_state_recognized( params )
	-- print( "Gesture:do_state_recognized", self._id )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--
	self:setState( Gesture.STATE_RECOGNIZED )
	self:_dispatchGestureNotification( params.notify )
	self:_dispatchStateNotification( params.notify )
	self:_dispatchRecognizedEvent()
end

function Gesture:state_recognized( next_state, params )
	-- print( "Gesture:state_recognized: >> ", next_state )

	if next_state == Gesture.STATE_POSSIBLE then
		self:do_state_possible( params )

	else
		print( "WARNING :: Gesture:state_recognized " .. tostring( next_state ) )
	end
end


--== State Failed ==--

function Gesture:do_state_failed( params )
	-- print( "Gesture:do_state_failed", self._id )
	params = params or {}
	if params.notify==nil then params.notify=true end
	--==--
	self:setState( Gesture.STATE_FAILED )
	self:_dispatchStateNotification( params.notify )
end

function Gesture:state_failed( next_state, params )
	-- print( "Gesture:state_failed: >> ", next_state )

	if next_state == Gesture.STATE_POSSIBLE then
		self:do_state_possible( params )
	elseif next_state == Gesture.STATE_FAILED then
		-- pass
	else
		print( "WARNING :: Gesture:state_failed " .. tostring( next_state ) )
	end
end




return Gesture

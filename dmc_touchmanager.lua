--===================================================================--
-- dmc_touchmanager.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_touchmanager.lua
--===================================================================--

--[[

Copyright (C) 2012 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.1"


--===================================================================--
-- Imports
--===================================================================--


--===================================================================--
-- Setup, Constants
--===================================================================--

system.activate("multitouch")


--===================================================================--
-- Support Functions
--===================================================================--


-- createObjectTouchHandler()
--
-- creates special touch handler for objects
--
-- @param mgr reference to the Touch Manager object
-- @param obj reference to the object on which to apply the callback (optional)
-- @return return value of callback, or false if no callback available
--
local createObjectTouchHandler = function( mgr, obj )

	return function( event )

		local t = mgr:_getRegisteredTouch( event.id )

		if t then

			if not event.target then
				event.target = t.obj
			else
				event.dispatcher = event.target
				event.target = t.obj
			end
			
			event.isFocused = true

			if t.handler then
				return t.handler( event )
			else
				return t.obj:touch( event )
			end

		else

			local o = mgr:_getRegisteredObject( obj )

			if o then

				if not event.target then
					event.target = o.obj
				else
					event.dispatcher = event.target
					event.target = o.obj
				end

				if o.handler then
					return o.handler( event )
				else
					return o.obj:touch( event )
				end

			end

		end			

		return false
	end
end



--===================================================================--
-- Touch Manager Object
--===================================================================--

local TouchManager = {}


--== Constants ==--

TouchManager._objects = {} -- keyed on obj ; object keys: obj, handler
TouchManager._touches = {} -- keyed on event.id ; object keys: obj, handler 


--== Private Methods ==--

function TouchManager:_getRegisteredObject( obj )
	return self._objects[ obj ]
end

function TouchManager:_setRegisteredObject( obj, value )
	self._objects[ obj ] = value
end


function TouchManager:_getRegisteredTouch( event_id )
	return self._touches[ event_id ]
end

function TouchManager:_setRegisteredTouch( event_id, value )
	self._touches[ event_id ] = value
end


--== Public Methods / API ==--


-- register()
--
-- puts touch manager in control of touch events for this object
--
-- @param obj a Corona-type object
-- @param handler the function handler for the touch event (optional)
--
function TouchManager:register( obj, handler )

	local r
	-- check to see if obj already registered
	if not self:_getRegisteredObject( obj ) then

		r = { obj=obj, handler=handler }
		r.callback = createObjectTouchHandler( self, obj )
		self:_setRegisteredObject( obj, r )
		obj:addEventListener( "touch", r.callback )
	end
end

-- unregister()
--
-- removes touch manager control for touch events for this object
--
-- @param obj a Corona-type object
-- @param handler the function handler for the touch event (optional)
--
function TouchManager:unregister( obj, handler )
	local r = self:_getRegisteredObject( obj )
    if r then
	    self:_setRegisteredObject( obj, nil )
	    obj:removeEventListener( "touch", r.callback )
    end
end


-- setFocus()
--
-- sets focus on an object for a single touch event
--
-- @param obj a Corona-type object
-- @param event_id id of the touch event
--
function TouchManager:setFocus( obj, event_id )
	local o = self:_getRegisteredObject( obj )
	local r = { obj=obj, handler=o.handler }

	self:_setRegisteredTouch( event_id, r )
end

-- unsetFocus()
--
-- removes focus on an object for a single touch event
--
-- @param obj a Corona-type object
-- @param event_id id of the touch event
--
function TouchManager:unsetFocus( obj, event_id )
	self:_setRegisteredTouch( event_id, nil )
end



--== puts touch manager in control of global (runtime) touch events ==--

Runtime:addEventListener( "touch", createObjectTouchHandler( TouchManager ) )


return TouchManager

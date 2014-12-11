--====================================================================--
-- lua_megaphone.lua
--
--
-- by David McCuskey
-- Documentation:
--====================================================================--

--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

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

local VERSION = "1.0.0"



--====================================================================--
-- Megaphone Global Communicator
--====================================================================--

--[[

== Overview ==

The Megaphone is to be used for inter-app communication

This is a singleton by nature and is imported by the app controller
Because it is global, any other component, view, etc can gain access to it

As any global object it should be used for only _well-defined events_!


== Usage ==


=== Access ===

this is a global variable accessible anywhere in the application.
so far messages are in one direction. there is a distinct speaker and receiver.


=== Event Listener ===

listening for global messages (ie, addEventListener):
( o/f is object or function listener )

gMegaphone:listen( o/f )


sending global messages:

gMegaphone:say( gMegaphone.DATA_RENDER_REQUEST, { ...params...} )


ignoring global messages (ie, removeEventListener):
( o/f is object or function listener, same as listen )

gMegaphone:ignore( o/f )

--]]



--====================================================================--
-- Imports

local Objects = require 'lua_objects'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase



--====================================================================--
-- Megaphone Object
--====================================================================--

local Megaphone = inheritsFrom( ObjectBase )

--== Event Constants

Megaphone.EVENT = "megaphone_event"


--======================================================--
-- Support Methods

function Megaphone:say( message, params )
	--print("Megaphone:say ", message )
	self:dispatchEvent( message, params )
end
function Megaphone:listen( listener )
	-- print("Megaphone:listen " )
	self:addEventListener( Megaphone.EVENT, listener )
end
function Megaphone:ignore( listener )
	-- print("Megaphone:ignore " )
	self:removeEventListener( Megaphone.EVENT, listener )
end




return Megaphone

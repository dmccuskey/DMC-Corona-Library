--====================================================================--
-- dmc_wamp.messages
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_wamp.lua
--====================================================================--

--[[

Copyright (C) 2014 David McCuskey. All Rights Reserved.

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

--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local json = require 'json'
local Objects = require( dmc_lib_func.find('dmc_objects') )
local Utils = require( dmc_lib_func.find('dmc_utils') )


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase



--====================================================================--
-- Message Base Class
--====================================================================--

local Message = inheritsFrom( ObjectBase )
Message.NAME = "Message Base Class"

function Message:_init( params )
	-- print( "Message:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	self.serialized = {}

end

function Message:serialize( serializer )
	-- print( "Message:serialize", serializer )
	return serializer:serialize( self:marshal() )
end



--====================================================================--
-- Hello Message Class
--====================================================================--

-- Format: `[ HELLO, Realm|uri, Details|dict ]`

local Hello = inheritsFrom( Message )
Hello.NAME = "Hello Message Class"

Hello.TYPE = 1  -- wamp message code

function Hello:_init( params )
	-- print( "Hello:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	if not self.is_intermediate and not ( params.realm or type(params.realm)~='string' ) then
		error( "Hello Message: requires parameter 'realm'" )
	end
	if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
		error( "Hello Message: requires parameter 'roles'" )
	end

	--== Create Properties ==--

	self.realm = params.realm
	self.roles = params.roles
	-- self.authmethods = authmethods

end

function Hello:marshal()
	-- print( "Hello:marshal" )
	local details = { roles={} }

	local ref -- reference to data
	for i, role in ipairs( self.roles ) do
		details.roles[ role.ROLE ] = Utils.encodeLuaTable( {} )
		-- print( 'role', i, role, role.ROLE )
		ref = details.roles[ role.ROLE ]
		for i, feature in ipairs( role.features ) do
			-- print( 'feature', i, feature)
			if not ref.features then ref.features = {} end
		end
	end
	details = Utils.encodeLuaTable( details )

	return { Hello.TYPE, self.realm, details }
end



--====================================================================--
-- Welcome Message Class
--====================================================================--

-- Format: `[WELCOME, Session|id, Details|dict]`

local Welcome = inheritsFrom( Message )
Welcome.NAME = "Welcome Message Class"

Welcome.TYPE = 2  -- wamp message code

function Welcome:_init( params )
	-- print( "Welcome:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.session = params.session
	self.roles = params.roles
	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod

end

-- Static function
function Welcome.parse( wmsg )
	-- print( "Welcome.parse", wmsg )

	local p = {
		session = wmsg[2],
		roles = wmsg[3]
	}
	return Welcome:new( p )

end




--====================================================================--
-- Abort Message Class
--====================================================================--

--====================================================================--
-- Challenge Message Class
--====================================================================--

--====================================================================--
-- Authenticate Message Class
--====================================================================--



--====================================================================--
-- Goodbye Message Class
--====================================================================--

-- Format: `[GOODBYE, Details|dict, Reason|uri]`

local Goodbye = inheritsFrom( Message )
Goodbye.NAME = "Goodbye Message Class"

Goodbye.TYPE = 6  -- wamp message code
Goodbye.DEFAULT_REASON = 'wamp.goodbye.normal'

function Goodbye:_init( params )
	-- print( "Goodbye:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	self.reason = params.reason or Goodbye.DEFAULT_REASON
	self.message = params.message

end

-- Static function
function Goodbye.parse( wmsg )
	-- print( "Goodbye.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Goodbye.TYPE )
	if #wmsg ~= 3 then
		error("wrong length, error")
	end

	local p = {
		details = wmsg[2],
		reason = wmsg[3],
	}
	return Goodbye:new( p )
end

function Goodbye:marshal()
	-- print( "Goodbye:marshal" )

	local details = {
		message = self.message
	}
	details = Utils.encodeLuaTable( details )

	return { Goodbye.TYPE, details, self.reason }
end



--====================================================================--
-- Heartbeat Message Class
--====================================================================--



--====================================================================--
-- Error Message Class
--====================================================================--

--[[
Formats:
* `[ERROR, REQUEST.Type|int, REQUEST.Request|id, Details|dict, Error|uri]`
* `[ERROR, REQUEST.Type|int, REQUEST.Request|id, Details|dict, Error|uri, Arguments|list]`
* `[ERROR, REQUEST.Type|int, REQUEST.Request|id, Details|dict, Error|uri, Arguments|list, ArgumentsKw|dict]`
--]]

local Error = inheritsFrom( Message )
Error.NAME = "Error Message Class"

Error.TYPE = 8  -- wamp message code

--====================================================================--
--== Start: Setup DMC Objects

function Error:_init( params )
	-- print( "Error:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.request_type = params.request_type
	self.request = params.request
	self.procedure = params.procedure
	self.error = params.error
	self.args = params.args
	self.kwargs = params.kwargs

end

--== END: Setup DMC Objects
--====================================================================--


-- Static function
function Error.parse( wmsg )
	-- print( "Error.parse", wmsg )

	--== Sanity Check ==--

	assert( #wmsg > 0 and wmsg[1] == Error.TYPE )

	if not Utils.propertyIn( { 5, 6, 7 }, #wmsg ) then
		error("wrong length, error")
	end

	--== Processing ==--

	local p = {
		request_type = wmsg[2],
		details = wmsg[3],
		error = wmsg[4],
		args = wmsg[5],
		kwargs = wmsg[6]
	}
	return Error:new( p )
end


function Error:marshal()
	-- print( "Error:marshal" )

	-- local options = {
	-- 	timeout = self.timeout,
	-- 	receive_progress = self.receive_progress,
	-- 	disclose_me = self.discloseMe
	-- }

	-- options = Utils.encodeLuaTable( options )
	-- self.kwargs = Utils.encodeLuaTable( self._kwargs )

	-- if self._kwargs then
	-- 	return { Error.TYPE, self.request, options, self.procedure, self.args, self._kwargs }
	-- elseif self._args then
	-- 	return { Error.TYPE, self.request, options, self.procedure, self.args }
	-- else
	-- 	return { Error.TYPE, self.request, options, self.procedure }
	-- end
end



--====================================================================--
-- Publish Message Class
--====================================================================--

--====================================================================--
-- Published Message Class
--====================================================================--




--====================================================================--
-- Subscribe Message Class
--====================================================================--


--[[
Format: `[SUBSCRIBE, Request|id, Options|dict, Topic|uri]`
--]]

local Subscribe = inheritsFrom( Message )
Subscribe.NAME = "Subscribe Message Class"

Subscribe.TYPE = 32  -- wamp message code

Subscribe.MATCH_EXACT = 'exact'
Subscribe.MATCH_PREFIX = 'prefix'
Subscribe.MATCH_WILDCARD = 'wildcard'


function Subscribe:_init( params )
	-- print( "Subscribe:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.request = params.request
	self.topic = params.topic
	self.match = params.match

end


function Subscribe.parse( wmsg )
	-- print( "Subscribe.parse", wmsg )

	-- Sanity Check

	assert( #wmsg > 0 and wmsg[1] == Subscribe.TYPE )

	if not Utils.propertyIn( { 3, 4, 5 }, #wmsg ) then
		error("wrong length, Subscribe")
	end

	-- Processing

	local p = {
		request = wmsg[2],
		details = wmsg[3],
		args = wmsg[4],
		kwargs = wmsg[5]
	}
	return Subscribe:new( p )
end


function Subscribe:marshal()
	-- print( "Subscribe:marshal" )

	local options = {}

	if self.match and self.match ~= Subscribe.MATCH_EXACT then
		options.match = self.match
	end

	options = Utils.encodeLuaTable( options )

	return { Subscribe.TYPE, self.request, options, self.topic }
end



--====================================================================--
-- Subscribed Message Class
--====================================================================--

--[[
Format: `[SUBSCRIBE, Request|id, Options|dict, Topic|uri]`
--]]

local Subscribed = inheritsFrom( Message )
Subscribed.NAME = "Subscribed Message Class"

Subscribed.TYPE = 33  -- wamp message code


function Subscribed:_init( params )
	-- print( "Subscribed:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.request = params.request
	self.subscription = params.subscription

end


function Subscribed.parse( wmsg )
	-- print( "Subscribed.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Subscribed.TYPE )

	if #wmsg ~= 3 then
		error("wrong length, Subscribed")
	end

	-- Processing
	local p = {
		request = wmsg[2],
		subscription = wmsg[3],
	}
	return Subscribed:new( p )
end


function Subscribed:marshal()
	-- print( "Subscribed:marshal" )
	return { Subscribed.TYPE, self.request, self.subscription }
end



--====================================================================--
-- Unsubscribe Message Class
--====================================================================--

--[[
Format: `[UNSUBSCRIBE, Request|id, SUBSCRIBED.Subscription|id]`
--]]

local Unsubscribe = inheritsFrom( Message )
Unsubscribe.NAME = "Unsubscribe Message Class"

Unsubscribe.TYPE = 34  -- wamp message code


function Unsubscribe:_init( params )
	-- print( "Unsubscribe:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.request = params.request
	self.subscription_id = params.subscription_id

end


function Unsubscribe.parse( wmsg )
	-- print( "Unsubscribe.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Unsubscribe.TYPE )

	if #wmsg ~= 3 then
		error("wrong length, Unsubscribe")
	end

	-- Processing
	local p = {
		request = wmsg[2],
		subscription = wmsg[3],
	}
	return Unsubscribe:new( p )
end


function Unsubscribe:marshal()
	-- print( "Unsubscribe:marshal" )
	local id = Utils.encodeLuaInteger( self.subscription_id )

	return { Unsubscribe.TYPE, self.request, id }
end



--====================================================================--
-- Unsubscribed Message Class
--====================================================================--

local Unsubscribed = inheritsFrom( Message )
Unsubscribed.NAME = "Unsubscribed Message Class"

Unsubscribed.TYPE = 35  -- wamp message code


function Unsubscribed:_init( params )
	-- print( "Unsubscribed:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.request = params.request

end


function Unsubscribed.parse( wmsg )
	-- print( "Unsubscribed.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Unsubscribed.TYPE )

	if #wmsg ~= 2 then
		error("wrong length, Unsubscribed")
	end

	-- Processing
	local p = {
		request = wmsg[2],
	}
	return Unsubscribed:new( p )
end


function Unsubscribed:marshal()
	-- print( "Unsubscribed:marshal" )
	return { Unsubscribed.TYPE, self.request, self.subscription }
end



--====================================================================--
-- Event Message Class
--====================================================================--

--[[
Formats:
* `[EVENT, SUBSCRIBED.Subscription|id, PUBLISHED.Publication|id, Details|dict]`
* `[EVENT, SUBSCRIBED.Subscription|id, PUBLISHED.Publication|id, Details|dict, PUBLISH.Arguments|list]`
* `[EVENT, SUBSCRIBED.Subscription|id, PUBLISHED.Publication|id, Details|dict, PUBLISH.Arguments|list, PUBLISH.ArgumentsKw|dict]`
--]]

local Event = inheritsFrom( Message )
Event.NAME = "Event Message Class"

Event.TYPE = 36  -- wamp message code


function Event:_init( params )
	-- print( "Event:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.subscription = params.subscription
	self.publication = params.publication
	-- self.details = params.details
	self.args = params.args
	self.kwargs = params.kwargs
	self.publisher = params.publisher

end


function Event.parse( wmsg )
	-- print( "Event.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Event.TYPE )

	if not Utils.propertyIn( { 4, 5, 6 }, #wmsg ) then
		error("wrong length, result")
	end

	-- Processing
	local p = {
		subscription = wmsg[2],
		publication = wmsg[3],
		-- details = wmsg[4],
		args = wmsg[5],
		kwargs = wmsg[6],
	}
	return Event:new( p )
end


function Event:marshal()
	-- print( "Event:marshal" )
	return { Event.TYPE, self.request, self.subscription }
end



--====================================================================--
-- Call Message Class
--====================================================================--

--[[
Formats:
* `[CALL, Request|id, Options|dict, Procedure|uri]`
* `[CALL, Request|id, Options|dict, Procedure|uri, Arguments|list]`
* `[CALL, Request|id, Options|dict, Procedure|uri, Arguments|list, ArgumentsKw|dict]`
--]]

local Call = inheritsFrom( Message )
Call.NAME = "Call Message Class"

Call.TYPE = 48  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Call:_init( params )
	-- print( "Call:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.request = params.request
	self.procedure = params.procedure
	self.args = params.args
	self.kwargs = params.kwargs
	self.timeout = params.timeout
	self.receive_progress = params.receive_progress
	self.discloseMe = params.discloseMe

end

--== END: Setup DMC Objects
--====================================================================--


-- -- Static function
-- function Call.parse( wmsg )
-- 	print( "Call.parse", wmsg )
-- 	Utils.print( wmsg )

-- 	local p = {
-- 		session = wmsg[2],
-- 		roles = wmsg[3]
-- 	}
-- 	return Welcome:new( p )

-- end


function Call:marshal()
	-- print( "Call:marshal" )

	local options = {
		timeout = self.timeout,
		receive_progress = self.receive_progress,
		disclose_me = self.discloseMe
	}

	options = Utils.encodeLuaTable( options )
	self.kwargs = Utils.encodeLuaTable( self.kwargs )

	if self.kwargs then
		return { Call.TYPE, self.request, options, self.procedure, self.args, self.kwargs }
	elseif self.args then
		return { Call.TYPE, self.request, options, self.procedure, self.args }
	else
		return { Call.TYPE, self.request, options, self.procedure }
	end
end



--====================================================================--
-- Cancel Message Class
--====================================================================--



--====================================================================--
-- Result Message Class
--====================================================================--

--[[
Formats:
	* `[RESULT, CALL.Request|id, Details|dict]`
	* `[RESULT, CALL.Request|id, Details|dict, YIELD.Arguments|list]`
	* `[RESULT, CALL.Request|id, Details|dict, YIELD.Arguments|list, YIELD.ArgumentsKw|dict]`
--]]

local Result = inheritsFrom( Message )
Result.NAME = "Result Message Class"

Result.TYPE = 50  -- wamp message code

function Result:_init( params )
	-- print( "Result:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and not ( params.session or type(params.realm)~='string' ) then
	-- 	error( "Welcome Message: requires parameter 'realm'" )
	-- end
	-- if not self.is_intermediate and not ( params.roles or type(params.realm)~='table' )  then
	-- 	error( "Welcome Message: requires parameter 'roles'" )
	-- end

	--== Create Properties ==--

	self.request = params.request
	self.args = params.args
	self.kwargs = params.kwargs
	self.progress = params.progress

end

function Result.parse( wmsg )
	-- print( "Result.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Result.TYPE )

	if not Utils.propertyIn( { 3, 4, 5 }, #wmsg ) then
		error("wrong length, result")
	end

	-- Processing
	local p = {
		request = wmsg[2],
		details = wmsg[3],
		args = wmsg[4],
		kwargs = wmsg[5]
	}
	return Result:new( p )

end

function Result:marshal()
	-- print( "Result:marshal" )

	-- local options = {
	-- 	timeout = self._timeout,
	-- 	receive_progress = self._receive_progress,
	-- 	disclose_me = self._discloseMe
	-- }

	-- options = Utils.encodeLuaTable( options )
	-- self._kwargs = Utils.encodeLuaTable( self._kwargs )

	-- if self._kwargs then
	-- 	return { Result.TYPE, self._request, options, self._procedure, self._args, self._kwargs }
	-- elseif self._args then
	-- 	return { Result.TYPE, self._request, options, self._procedure, self._args }
	-- else
	-- 	return { Result.TYPE, self._request, options, self._procedure }
	-- end
end



--====================================================================--
-- Register Message Class
--====================================================================--

--====================================================================--
-- Registered Message Class
--====================================================================--

--====================================================================--
-- Unregister Message Class
--====================================================================--

--====================================================================--
-- Invocation Message Class
--====================================================================--

--====================================================================--
-- Interrupt Message Class
--====================================================================--

--====================================================================--
-- Yield Message Class
--====================================================================--




--====================================================================--
-- Message Factory
--====================================================================--

local MessageFactory = {}


--== Class References

MessageFactory.Hello = Hello
MessageFactory.Welcome = Welcome
MessageFactory.Goodbye = Goodbye
MessageFactory.Error = Error
MessageFactory.Subscribe = Subscribe
MessageFactory.Subscribed = Subscribed
MessageFactory.Unsubscribe = Unsubscribe
MessageFactory.Unsubscribed = Unsubscribed
MessageFactory.Event = Event
MessageFactory.Call = Call
MessageFactory.Result = Result


--== Type-Class Mapping

MessageFactory.map = {
	[Hello.TYPE] = Hello,
	[Welcome.TYPE] = Welcome,
	[Goodbye.TYPE] = Goodbye,
	[Error.TYPE] = Error,
	[Subscribe.TYPE] = Subscribe,
	[Subscribed.TYPE] = Subscribed,
	[Unsubscribe.TYPE] = Unsubscribe,
	[Unsubscribed.TYPE] = Unsubscribed,
	[Event.TYPE] = Event,
	[Call.TYPE] = Call,
	[Result.TYPE] = Result,
}


function MessageFactory.create( msg_type, params )
	-- print( "MessageFactory.create", msg_type )

	local o

	if msg_type == Hello.TYPE then
		o = Hello:new( params )

	elseif msg_type == Welcome.TYPE then
		o = Welcome:new( params )

	elseif msg_type == Goodbye.TYPE then
		o = Goodbye:new( params )

	elseif msg_type == Error.TYPE then
		o = Error:new( params )

	elseif msg_type == Subscribe.TYPE then
		o = Subscribe:new( params )

	elseif msg_type == Subscribed.TYPE then
		o = Subscribed:new( params )

	elseif msg_type == Unsubscribe.TYPE then
		o = Unsubscribe:new( params )

	elseif msg_type == Unsubscribed.TYPE then
		o = Unsubscribed:new( params )

	elseif msg_type == Event.TYPE then
		o = Event:new( params )

	elseif msg_type == Call.TYPE then
		o = Call:new( params )

	elseif msg_type == Result.TYPE then
		o = Result:new( params )

	else
		error( "ERROR, message factory", msg_type )
	end

	return o
end


return MessageFactory

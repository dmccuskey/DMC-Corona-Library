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


--====================================================================--
-- DMC Corona Library : Message
--====================================================================--


--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local json = require 'json'

local Objects = require 'lua_objects'
local Utils = require 'lua_utils'


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


--[[
Format:
* `[PUBLISH, Request|id, Options|dict, Topic|uri]`
* `[PUBLISH, Request|id, Options|dict, Topic|uri, Arguments|list]`
* `[PUBLISH, Request|id, Options|dict, Topic|uri, Arguments|list, ArgumentsKw|dict]`
--]]

local Publish = inheritsFrom( Message )
Publish.NAME = "Publish Message Class"

Publish.TYPE = 16  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Publish:_init( params )
	-- print( "Publish:_init" )
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
	self.args = params.args
	self.kwargs = params.kwargs

	-- clean up args
	local opts = params.options or {}
	self.options = {
		acknowledge=opts.acknowledge,
		exclude_me=opts.exclude_me,
		exclude=opts.exclude,
		eligible=opts.eligible,
		disclose_me=opts.disclose_me
	}

end

--== END: Setup DMC Objects
--====================================================================--


-- -- Static function
-- function Publish.parse( wmsg )
-- 	print( "Publish.parse", wmsg )
-- 	Utils.print( wmsg )

-- 	local p = {
-- 		session = wmsg[2],
-- 		roles = wmsg[3]
-- 	}
-- 	return Welcome:new( p )

-- end


function Publish:marshal()
	-- print( "Publish:marshal" )

	local pub_id = Utils.encodeLuaInteger( self.request )
	local options = Utils.encodeLuaTable( self.options )
	self.kwargs = Utils.encodeLuaTable( self.kwargs )

	if self.kwargs then
		return { Publish.TYPE, pub_id, options, self.topic, self.args, self.kwargs }
	elseif self.args then
		return { Publish.TYPE, pub_id, options, self.topic, self.args }
	else
		return { Publish.TYPE, pub_id, options, self.topic }
	end

end



--====================================================================--
-- Published Message Class
--====================================================================--


--[[
Format:
* `[PUBLISHED, PUBLISH.Request|id, Publication|id]`
--]]

local Published = inheritsFrom( Message )
Published.NAME = "Published Message"

Published.TYPE = 17  -- wamp message code

function Published:_init( params )
	-- print( "Published:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	assert( params.request, "Published Message: missing request" )
	assert( params.publication, "Published Message: missing publication" )

	self.request = params.request
	self.publication = params.publication

end

function Published.parse( wmsg )
	-- print( "Published.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Published.TYPE )

	if #wmsg ~= 3 then
		error("wrong length, Published")
	end

	-- TODO: check these
	local request = wmsg[2]
	local publication = wmsg[3]

	return Published:new{
		request=request,
		publication=publication
	}

end

function Published:marshal()
	-- print( "Published:marshal" )
	return { Published.TYPE, self.request, self.publication }
end



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


--[[
Format:
* `[REGISTER, Request|id, Options|dict, Procedure|uri]`
--]]

local Register = inheritsFrom( Message )
Register.NAME = "Register Message Class"

Register.TYPE = 64  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Register:_init( params )
	-- print( "Register:_init" )
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
	self.pkeys = params.pkeys
	self.disclose_caller = params.disclose_caller

end

--== END: Setup DMC Objects
--====================================================================--


-- -- Static function
-- function Register.parse( wmsg )
-- 	print( "Register.parse", wmsg )
-- 	Utils.print( wmsg )

-- 	local p = {
-- 		session = wmsg[2],
-- 		roles = wmsg[3]
-- 	}
-- 	return Welcome:new( p )

-- end


function Register:marshal()
	print( "Register:marshal" )

	local options = {
		pkeys = self.pkeys,
		discloseCaller = self.disclose_caller,
	}

	options = Utils.encodeLuaTable( options )
	self.kwargs = Utils.encodeLuaTable( self.kwargs )

	return { Register.TYPE, self.request, options, self.procedure }
end



--====================================================================--
-- Registered Message Class
--====================================================================--


--[[
Format:
* `[REGISTERED, REGISTER.Request|id, Registration|id]`
--]]

local Registered = inheritsFrom( Message )
Registered.NAME = "Registered Message Class"

Registered.TYPE = 65  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Registered:_init( params )
	-- print( "Registered:_init" )
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
	self.registration = params.registration

end

--== END: Setup DMC Objects
--====================================================================--


-- Static function
function Registered.parse( wmsg )
	print( "Registered.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Registered.TYPE )

	if #wmsg ~= 3 then
		error("wrong length, result")
	end

	local p = {
		request = wmsg[2],
		registration = wmsg[3]
	}
	return Registered:new( p )

end


-- function Registered:marshal()
-- 	print( "Registered:marshal" )

-- 	local options = {
-- 		pkeys = self.pkeys,
-- 		discloseCaller = self.disclose_caller,
-- 	}

-- 	options = Utils.encodeLuaTable( options )
-- 	self.kwargs = Utils.encodeLuaTable( self.kwargs )

-- 	return { Registered.TYPE, self.request, options, self.procedure }
-- end



--====================================================================--
-- Unregister Message Class
--====================================================================--


--[[
Format:
* `[UNREGISTER, Request|id, REGISTERED.Registration|id]`
--]]

local Unregister = inheritsFrom( Message )
Unregister.NAME = "Unregister Message Class"

Unregister.TYPE = 66  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Unregister:_init( params )
	-- print( "Unregister:_init" )
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
	self.registration = params.registration -- id

end

--== END: Setup DMC Objects
--====================================================================--


-- -- Static function
-- function Unregister.parse( wmsg )
-- 	print( "Unregister.parse", wmsg )
-- 	Utils.print( wmsg )

-- 	local p = {
-- 		session = wmsg[2],
-- 		roles = wmsg[3]
-- 	}
-- 	return Welcome:new( p )

-- end


function Unregister:marshal()
	print( "Unregister:marshal" )

	local req_id = Utils.encodeLuaInteger( self.request )
	local reg_id = Utils.encodeLuaInteger( self.registration )

	return { Unregister.TYPE, req_id, reg_id }
end



--====================================================================--
-- Unregistered Message Class
--====================================================================--


local Unregistered = inheritsFrom( Message )
Unregistered.NAME = "Unregistered Message Class"

Unregistered.TYPE = 67  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Unregistered:_init( params )
	-- print( "Unregistered:_init" )
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

--== END: Setup DMC Objects
--====================================================================--


-- Static function
function Unregistered.parse( wmsg )
	print( "Unregistered.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Unregistered.TYPE )

	if #wmsg ~= 2 then
		error("wrong length, Unregistered")
	end

	local request = wmsg[2]

	return Unregistered:new{
		request=request
	}

end


-- function Unregistered:marshal()
-- 	print( "Unregistered:marshal" )

-- 	local options = {
-- 		pkeys = self.pkeys,
-- 		discloseCaller = self.disclose_caller,
-- 	}

-- 	options = Utils.encodeLuaTable( options )
-- 	self.kwargs = Utils.encodeLuaTable( self.kwargs )

-- 	return { Unregistered.TYPE, self.request, options, self.procedure }
-- end




--====================================================================--
-- Invocation Message Class
--====================================================================--


--[[
Formats:
* `[INVOCATION, Request|id, REGISTERED.Registration|id, Details|dict]`
* `[INVOCATION, Request|id, REGISTERED.Registration|id, Details|dict, CALL.Arguments|list]`
* `[INVOCATION, Request|id, REGISTERED.Registration|id, Details|dict, CALL.Arguments|list, CALL.ArgumentsKw|dict]`
--]]

local Invocation = inheritsFrom( Message )
Invocation.NAME = "Invocation Message Class"

Invocation.TYPE = 68  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Invocation:_init( params )
	-- print( "Invocation:_init" )
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
	self.registration = params.registration
	self.args = params.args
	self.kwargs = params.kwargs
	self.timeout = params.timeout
	self.receive_progress = params.receive_progress
	self.caller = params.caller
	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod

end

--== END: Setup DMC Objects
--====================================================================--


-- Static function
function Invocation.parse( wmsg )
	print( "Invocation.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Invocation.TYPE )

	if not Utils.propertyIn( { 4, 5, 6 }, #wmsg ) then
		error("wrong length, Invocation")
	end

	local p, details

	p = {
		request = wmsg[2],
		registration = wmsg[3],
		args = wmsg[5],
		kwargs = wmsg[6],
	}

	details = wmsg[4] or {}
	p.timeout = details.timeout
	p.receive_progress = details.receive_progress
	p.authid = details.authid
	p.authrole = details.authrole
	p.authmethod = details.authmethod

	return Invocation:new( p )

end


-- function Invocation:marshal()
-- 	print( "Invocation:marshal" )

-- 	local options = {
-- 		pkeys = self.pkeys,
-- 		discloseCaller = self.disclose_caller,
-- 	}

-- 	options = Utils.encodeLuaTable( options )
-- 	self.kwargs = Utils.encodeLuaTable( self.kwargs )

-- 	return { Invocation.TYPE, self.request, options, self.procedure }
-- end



--====================================================================--
-- Interrupt Message Class
--====================================================================--


--====================================================================--
-- Yield Message Class
--====================================================================--


--[[
Format:
* `[YIELD, INVOCATION.Request|id, Options|dict]`
* `[YIELD, INVOCATION.Request|id, Options|dict, Arguments|list]`
* `[YIELD, INVOCATION.Request|id, Options|dict, Arguments|list, ArgumentsKw|dict]`
--]]

local Yield = inheritsFrom( Message )
Yield.NAME = "Yield Message Class"

Yield.TYPE = 70  -- wamp message code


--====================================================================--
--== Start: Setup DMC Objects

function Yield:_init( params )
	-- print( "Yield:_init" )
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

--== END: Setup DMC Objects
--====================================================================--


-- -- Static function
-- function Yield.parse( wmsg )
-- 	print( "Yield.parse", wmsg )
-- 	Utils.print( wmsg )

-- 	local p = {
-- 		session = wmsg[2],
-- 		roles = wmsg[3]
-- 	}
-- 	return Welcome:new( p )

-- end


function Yield:marshal()
	print( "Yield:marshal" )

	local id = Utils.encodeLuaInteger( self.request )
	local options = {
		progress = self.progress,
	}
	options = Utils.encodeLuaTable( options )


	if self.kwargs then
		self.kwargs = Utils.encodeLuaTable( self.kwargs )
		return { Yield.TYPE, id, options, self.args, self.kwargs }
	elseif self.args then
		return { Yield.TYPE, id, options, self.args }
	else
		return { Yield.TYPE, id, options }
	end
end



--====================================================================--
-- Message Factory
--====================================================================--


local MessageFactory = {}

--== Class References

MessageFactory.Hello = Hello
MessageFactory.Welcome = Welcome
MessageFactory.Goodbye = Goodbye
MessageFactory.Error = Error
MessageFactory.Publish = Publish
MessageFactory.Published = Published
MessageFactory.Subscribe = Subscribe
MessageFactory.Subscribed = Subscribed
MessageFactory.Unsubscribe = Unsubscribe
MessageFactory.Unsubscribed = Unsubscribed
MessageFactory.Event = Event
MessageFactory.Call = Call
MessageFactory.Result = Result
MessageFactory.Register = Register
MessageFactory.Registered = Registered
MessageFactory.Unregister = Unregister
MessageFactory.Unregistered = Unregistered
MessageFactory.Invocation = Invocation
MessageFactory.Yield = Yield

--== Type-Class Mapping

MessageFactory.map = {
	[Hello.TYPE] = Hello,
	[Welcome.TYPE] = Welcome,
	[Goodbye.TYPE] = Goodbye,
	[Error.TYPE] = Error,
	[Publish.TYPE] = Publish,
	[Published.TYPE] = Published,
	[Subscribe.TYPE] = Subscribe,
	[Subscribed.TYPE] = Subscribed,
	[Unsubscribe.TYPE] = Unsubscribe,
	[Unsubscribed.TYPE] = Unsubscribed,
	[Event.TYPE] = Event,
	[Call.TYPE] = Call,
	[Result.TYPE] = Result,
	[Register.TYPE] = Register,
	[Registered.TYPE] = Registered,
	[Unregister.TYPE] = Unregister,
	[Unregistered.TYPE] = Unregistered,
	[Invocation.TYPE] = Invocation,
	[Yield.TYPE] = Yield,
}


return MessageFactory

--====================================================================--
-- dmc_corona/dmc_wamp/messages.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014-2015 David McCuskey

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
--== DMC Corona Library : DMC WAMP Message
--====================================================================--


--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local json = require 'json'

local Objects = require 'lib.dmc_lua.lua_objects'
local Utils = require 'lib.dmc_lua.lua_utils'

local WError = require 'dmc_wamp.exception'
local WUtils = require 'dmc_wamp.utils'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass


-- strict URI check allowing empty URI components
local _URI_PAT_STRICT_EMPTY = "^(([0-9a-z_]+\.)|\.)*([0-9a-z_]+)?$" -- original
_URI_PAT_STRICT_EMPTY = "([0-9a-z_]+%.?)"

-- loose URI check allowing empty URI components
local _URI_PAT_LOOSE_EMPTY = "^(([^\s\.#]+\.)|\.)*([^\s\.#]+)?$" -- original
_URI_PAT_LOOSE_EMPTY = "([^%s%.%#]+%.?)"

-- strict URI check disallowing empty URI components
local _URI_PAT_STRICT_NON_EMPTY = "^([0-9a-z_]+\.)*([0-9a-z_]+)$"
_URI_PAT_STRICT_NON_EMPTY = "([0-9a-z_]+%.?)"

-- loose URI check disallowing empty URI components

local _URI_PAT_LOOSE_NON_EMPTY = "^([^%s\.#]+\.)*([^%s\.#]+)$" -- original
_URI_PAT_LOOSE_NON_EMPTY = "([^%s%.%#]+%.?)"


local Hello, Welcome, Abort, Challenge, Authenticate, Goodbye
local Heartbeat, Error
local Subscribe, Subscribed, Unsubscribe, Unsubscribed
local Publish, Event, Published
local Register, Registered, Unregister, Unregistered
local Call, Invocation, Result, Cancel, Interrupt, Yield



--====================================================================--
--== Support Functions


local function check_or_raise_uri( params )
	-- print( "check_or_raise_uri" )
	params = params or {}
	params.message = params.message or "WAMP message invalid"
	params.strict = params.strict ~= nil and params.strict or false
	params.allowEmptyComponents = params.allowEmptyComponents ~= nil and params.allowEmptyComponents or false
	--==--

	if type( params.value ) ~= 'string' then
		error( WError.ProtocolError( "{0}: invalid type {1}" ) )
	end

	local pat, length

	if params.strict then
		if params.allowEmptyComponents then
			pat = _URI_PAT_STRICT_EMPTY
		else
			pat = _URI_PAT_STRICT_NON_EMPTY
		end
	else
		if params.allowEmptyComponents then
			pat = _URI_PAT_LOOSE_EMPTY
		else
			pat = _URI_PAT_LOOSE_NON_EMPTY
		end
	end

	-- TODO: this checking part needs work
	-- right now a total hack, Lua doesn't have built in RegEx

	-- print( pat, params.value, string.find( params.value, pat )  )
	length = 0
	for word in string.gmatch( params.value, pat ) do
		length = length + #word
	end

	if length ~= #params.value then
		error( WError.ProtocolError( "{0}: invalid type {1}" ) )
	end

	return params.value
end



local function check_or_raise_id( params )
	-- print( "check_or_raise_id" )
	params = params or {}
	params.message = params.message or "WAMP message invalid"
	--==--

	if type( params.value ) ~= 'number' then
		error( WError.ProtocolError( "{0}: invalid type {1}" ) )
	end
	if params.value < 0 or params.value > 9007199254740992 then -- 2**53
		error( WError.ProtocolError( "{0}: invalid type {1}" ) )
	end

	return params.value
end



local function check_or_raise_extra( params )
	-- print( "check_or_raise_extra" )
	params = params or {}
	params.message = params.message or "WAMP message invalid"
	--==--

	if type( params.value ) ~= 'table' then
		error( WError.ProtocolError( "{0}: invalid type {1}" ) )
	end

	for k,v in pairs( params.value ) do
		if type(k) ~= 'string' then
			error( WError.ProtocolError( "{0}: invalid type {1}" ) )
		end
	end

	return params.value
end



--====================================================================--
--== Message Base Class
--====================================================================--


local Message = newClass( nil, {name="Message Base"} )

function Message:__new__( params )
	-- print( "Message:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	self.serialized = {}

end

function Message:serialize( serializer )
	-- print( "Message:serialize", serializer )
	return serializer:serialize( self:marshal() )
end



--====================================================================--
--== Hello Message Class
--====================================================================--


-- Format: `[ HELLO, Realm|uri, Details|dict ]`

Hello = newClass( Message, {name="Hello Message"} )

Hello.MESSAGE_TYPE = 1  -- wamp message code

function Hello:__new__( params )
	-- print( "Hello:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( type( params.realm )=='string' )
	assert( type( params.roles )=='table' )
	-- TODO: check authmethods
	assert( params.authid == nil or type( params.authid )=='string' )

	self.realm = params.realm
	self.roles = params.roles
	self.authmethods = params.authmethods
	self.authid = params.authid

end


--[[
parse() method not implemeneted because only necessary for routers
--]]
-- function Hello:parse()
-- end


function Hello:marshal()
	-- print( "Hello:marshal" )
	local details = { roles={} }

	for i, role in ipairs( self.roles ) do
		local ref = {}  -- reference to data
		details.roles[ role.ROLE ] = {}
		-- print( 'role', i, role, role.ROLE )
		ref = details.roles[ role.ROLE ]
		for k, v in pairs( role:getFeatures() ) do
			-- print( 'feature', k, v)
			if not ref.features then ref.features = {} end
			ref.features[k]=v
		end
		details.roles[ role.ROLE ] = WUtils.encodeLuaTable( ref )
	end

	if self.authmethods then
		details.authmethods = self.authmethods
	end

	if self.authid then
		details.authid = self.authid
	end

	-- hack values
	details = WUtils.encodeLuaTable( details )

	return { Hello.MESSAGE_TYPE, self.realm, details }
end



--====================================================================--
--== Welcome Message Class
--====================================================================--


-- Format: `[WELCOME, Session|id, Details|dict]`

Welcome = newClass( Message, {name="Welcome Message"} )

Welcome.MESSAGE_TYPE = 2  -- wamp message code

function Welcome:__new__( params )
	-- print( "Welcome:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( type(params.session)=='number' )
	assert( type(params.roles)=='table' )
	assert( params.authid==nil or type(params.authid)=='string' )
	assert( params.authrole==nil or type(params.authrole)=='string' )
	assert( params.authmethod==nil or type(params.authmethod)=='string' )
	assert( params.authprovider==nil or type(params.authprovider)=='string' )

	self.session = params.session
	self.roles = params.roles
	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod
	self.authprovider = params.authprovider

end

-- Static function
function Welcome.parse( wmsg )
	-- print( "Welcome.parse", wmsg )

	return Welcome{
		session = wmsg[2],
		roles = wmsg[3]
	}

end


--[[
marshal() method not implemeneted because only necessary for routers
--]]
-- function Welcome:marshal()
-- end



--====================================================================--
--== Abort Message Class
--====================================================================--


-- Format: ``[ABORT, Details|dict, Reason|uri]``

Abort = newClass( Message, {name="Abort Message"} )

Abort.MESSAGE_TYPE = 3  -- wamp message code

function Abort:__new__( params )
	-- print( "Abort:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( type( params.reason )=='string' )
	assert( params.message == nil or type( params.message )=='string' )

	self.reason = params.reason
	self.message = params.message

end


-- Static function
function Abort.parse( wmsg )
	-- print( "Abort.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Abort.MESSAGE_TYPE )

	if #wmsg ~= 3 then
		error( WError.ProtocolError( "invalid message length {0} for ABORT" ) )
	end

	local details, reason, message

	details = check_or_raise_extra{ value=wmsg[2], message="'details' in ABORT" }
	reason = check_or_raise_uri{ value=wmsg[3], message="'reason' in ABORT" }

	if details and details.message then
		message = details.message
		if type( message ) ~= 'string' then
			error( WError.ProtocolError( "invalid type {0} for 'message' detail in ABORT" ) )
		end
	end

	return Abort{
		reason=reason,
		message=message
	}

end


--[[
marshal() method not implemeneted because only necessary for routers
--]]
-- function Challenge:marshal()
-- end



--====================================================================--
--== Challenge Message Class
--====================================================================--


-- Format: ``[CHALLENGE, Method|string, Extra|dict]``

Challenge = newClass( Message, {name="Challenge Message"} )

Challenge.MESSAGE_TYPE = 4  -- wamp message code

function Challenge:__new__( params )
	-- print( "Challenge:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( type( params.method )=='string' )
	assert( params.extra == nil or type( params.extra )=='table' )

	self.method = params.method
	self.extra = params.extra

end


-- Static function
function Challenge.parse( wmsg )
	-- print( "Challenge.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Challenge.MESSAGE_TYPE )

	if #wmsg ~= 3 then
		error( WError.ProtocolError( "invalid message length {0} for CHALLENGE" ) )
	end

	local method, extra

	method = wmsg[2]
	if type( method ) ~= 'string' then
		error( WError.ProtocolError( "invalid type {0} for 'method' in CHALLENGE" ) )
	end

	extra = check_or_raise_extra{ value=wmsg[3], message="'extra' in CHALLENGE" }

	return Challenge{
		method = method,
		extra = extra
	}

end


--[[
marshal() method not implemeneted because only necessary for routers
--]]
-- function Challenge:marshal()
-- end



--====================================================================--
--== Authenticate Message Class
--====================================================================--


-- Format: ``[AUTHENTICATE, Signature|string, Extra|dict]``

Authenticate = newClass( Message, {name="Authenticate Message"} )

Authenticate.MESSAGE_TYPE = 5  -- wamp message code

function Authenticate:__new__( params )
	-- print( "Authenticate:__new__" )
	params = params or {}
	params.extra = params.extra or {}
	self:superCall( '__new__', params )
	--==--
	assert( type( params.signature )=='string' )
	assert( params.extra == nil or type( params.extra )=='table' )

	self.signature = params.signature
	self.extra = params.extra

end


--[[
parse() method not implemented because only necessary for routers
--]]
-- function Authenticate:parse()
-- end


function Authenticate:marshal()
	-- print( "Authenticate:marshal" )
	local extra = WUtils.encodeLuaTable( self.extra )

	return { Authenticate.MESSAGE_TYPE, self.signature, extra }
end



--====================================================================--
--== Goodbye Message Class
--====================================================================--


-- Format: `[GOODBYE, Details|dict, Reason|uri]`

Goodbye = newClass( Message, {name="Goodbye Message"} )

Goodbye.MESSAGE_TYPE = 6  -- wamp message code
Goodbye.DEFAULT_REASON = 'wamp.goodbye.normal'

function Goodbye:__new__( params )
	-- print( "Goodbye:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type( params.reason )=='string' )
	assert( params.message == nil or type( params.message )=='string' )

	self.reason = params.reason or Goodbye.DEFAULT_REASON
	self.message = params.message

end

-- Static function
function Goodbye.parse( wmsg )
	-- print( "Goodbye.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Goodbye.MESSAGE_TYPE )
	if #wmsg ~= 3 then
		error( WError.ProtocolError( "invalid message length {0} for ERROR" ) )
	end

	local details, reason, message

	details = check_or_raise_extra{ value=wmsg[2], message="'details' in GOODBYE" }
	reason = check_or_raise_uri{ value=wmsg[3], message="'reason' in GOODBYE" }

	if details and details.message then
		message = details.message
		if type( message) ~= 'string' then
			error( WError.ProtocolError( "invalid type {0} for 'message' detail in ABORT" ) )
		end
	end

	return Goodbye{
		reason=reason,
		message=message
	}
end

function Goodbye:marshal()
	-- print( "Goodbye:marshal" )

	local details = {
		message = self.message
	}

	-- hack before sending
	details = WUtils.encodeLuaTable( details )

	return { Goodbye.MESSAGE_TYPE, details, self.reason }
end



--====================================================================--
--== Heartbeat Message Class
--====================================================================--


-- Formats:
-- ``[HEARTBEAT, Incoming|integer, Outgoing|integer]``
-- ``[HEARTBEAT, Incoming|integer, Outgoing|integer, Discard|string]``


Heartbeat = newClass( Message, {name="Heartbeat Message"} )

Heartbeat.MESSAGE_TYPE = 7  -- wamp message code

function Heartbeat:__new__( params )
	-- print( "Heartbeat:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( type( params.incoming ) == 'number' )
	assert( type( params.outgoing ) == 'number' )
	assert( params.discard == nil or type( params.discard ) == 'string' )

	self.incoming = params.incoming
	self.outgoing = params.outgoing
	self.discard = params.discard

end

-- Static function
function Heartbeat.parse( wmsg )
	-- print( "Heartbeat.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Heartbeat.MESSAGE_TYPE )

	if not Utils.propertyIn( { 3, 4 }, #wmsg ) then
		error( WError.ProtocolError( "invalid message length HEARTBEAT" ) )
	end

	local incoming, outgoing, discard

	incoming = wmsg[2]

	if type( incoming ) ~= 'number' then
		error( WError.ProtocolError( "invalid type 'incoming' HEARTBEAT" ) )
	end

	if incoming < 0 then
		error( WError.ProtocolError( "non negative 'incoming' HEARTBEAT" ) )
	end

	outgoing = wmsg[3]

	if type( outgoing ) ~= 'number' then
		error( WError.ProtocolError( "invalid type 'outgoing' HEARTBEAT" ) )
	end

	if outgoing <= 0 then
		error( WError.ProtocolError( "non negative 'outgoing' HEARTBEAT" ) )
	end

	discard = nil
	if #wmsg > 3 then
		discard = wmsg[4]

		if type( discard ) ~= 'string' then
			error( WError.ProtocolError( "invalid type 'discard' HEARTBEAT" ) )
		end
	end

	return Heartbeat{
		incoming=incoming,
		outgoing=outgoing,
		discard=discard
	}

end


function Heartbeat:marshal()
	-- print( "Heartbeat:marshal" )

	if self.discard then
		return { Heartbeat.MESSAGE_TYPE, self.incoming, self.outgoing, self.discard }
	else
		return { Heartbeat.MESSAGE_TYPE, self.incoming, self.outgoing }
	end

end



--====================================================================--
--== Error Message Class
--====================================================================--


--[[
Formats:
* `[ERROR, REQUEST.Type|int, REQUEST.Request|id, Details|dict, Error|uri]`
* `[ERROR, REQUEST.Type|int, REQUEST.Request|id, Details|dict, Error|uri, Arguments|list]`
* `[ERROR, REQUEST.Type|int, REQUEST.Request|id, Details|dict, Error|uri, Arguments|list, ArgumentsKw|dict]`
--]]

Error = newClass( Message, {name="Error Message"} )

Error.MESSAGE_TYPE = 8  -- wamp message code

function Error:__new__( params )
	-- print( "Error:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type( params.request_type )=='number' )
	assert( type( params.request )=='number' )
	assert( type( params.error )=='string' )
	assert( params.args == nil or type( params.args )=='table' )
	assert( params.kwargs == nil or type( params.kwargs )=='table' )

	self.request_type = params.request_type
	self.request = params.request
	self.procedure = params.procedure
	self.error = params.error
	self.args = params.args
	self.kwargs = params.kwargs

end


-- Static function
function Error.parse( wmsg )
	-- print( "Error.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Error.MESSAGE_TYPE )

	if not Utils.propertyIn( { 5, 6, 7 }, #wmsg ) then
		error( WError.ProtocolError( "invalid message length ERROR" ) )
	end

	local request_type, request, err, args, kwargs, _

	request_type = wmsg[2]
	if type(request_type) ~= 'number' then
		error( WError.ProtocolError( "invalid 'request_type' in ERROR" ) )
	end

	local REQUEST_TYPES = {
		Subscribe.MESSAGE_TYPE,
		Unsubscribe.MESSAGE_TYPE,
		Publish.MESSAGE_TYPE,
		Register.MESSAGE_TYPE,
		Unregister.MESSAGE_TYPE,
		Call.MESSAGE_TYPE,
		Invocation.MESSAGE_TYPE
	}

	if not Utils.propertyIn( REQUEST_TYPES, request_type ) then
		error( WError.ProtocolError( "invalid value for 'request_type' in ERROR" ) )
	end

	request = check_or_raise_id{ value=wmsg[3], message="'request' in ERROR" }
	_ = check_or_raise_extra{ value=wmsg[4], message="'details' in ERROR" }
	err = check_or_raise_uri{ value=wmsg[5], message="'error' in ERROR" }

	if #wmsg > 4 then
		args = wmsg[4]
		if type(args) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'args' in EVENT" ) )
		end
	end

	if #wmsg > 5 then
		kwargs = wmsg[5]
		if type(kwargs) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'kwargs' in EVENT" ) )
		end
	end


	return Error{
		request_type=request_type,
		details=details,
		error=error,
		args=args,
		kwargs=kwargs
	}

end


function Error:marshal()
	-- print( "Error:marshal" )

	-- local options = {
	-- 	timeout = self.timeout,
	-- 	receive_progress = self.receive_progress,
	-- 	discloseMe = self.discloseMe
	-- }

	-- options = WUtils.encodeLuaTable( options )
	-- self.kwargs = WUtils.encodeLuaTable( self._kwargs )

	-- if self._kwargs then
	-- 	return { Error.MESSAGE_TYPE, self.request, options, self.procedure, self.args, self._kwargs }
	-- elseif self._args then
	-- 	return { Error.MESSAGE_TYPE, self.request, options, self.procedure, self.args }
	-- else
	-- 	return { Error.MESSAGE_TYPE, self.request, options, self.procedure }
	-- end
end



--====================================================================--
--== Publish Message Class
--====================================================================--


--[[
Format:
* `[PUBLISH, Request|id, Options|dict, Topic|uri]`
* `[PUBLISH, Request|id, Options|dict, Topic|uri, Arguments|list]`
* `[PUBLISH, Request|id, Options|dict, Topic|uri, Arguments|list, ArgumentsKw|dict]`
--]]

Publish = newClass( Message, {name="Publish Message"} )

Publish.MESSAGE_TYPE = 16  -- wamp message code

function Publish:__new__( params )
	-- print( "Publish:__new__" )
	params = params or {}
	self:superCall( "__new__", params )
	--==--

	assert( type( params.request ) == 'number' )
	assert( type( params.topic ) == 'string' )
	assert( params.args == nil or type( params.args ) == 'table' )
	assert( params.kwargs == nil or type( params.kwargs ) == 'table' )
	assert( params.acknowledge == nil or type( params.acknowledge ) == 'boolean' )
	assert( params.excludeMe == nil or type( params.excludeMe ) == 'boolean' )
	assert( params.exclude == nil or type( params.exclude ) == 'boolean' )
	assert( params.eligible == nil or type( params.eligible ) == 'boolean' )
	assert( params.discloseMe == nil or type( params.discloseMe ) == 'boolean' )

	self.request = params.request
	self.topic = params.topic
	self.args = params.args
	self.kwargs = params.kwargs
	self.acknowledge = params.acknowledge
	self.excludeMe = params.excludeMe
	self.exclude = params.exclude
	self.eligible = params.eligible
	self.discloseMe = params.discloseMe

end

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

	local pub_id = self.request
	local options = {
		acknowledge = self.acknowledge,
		excludeMe = self.excludeMe,
		exclude = self.exclude,
		eligible = self.eligible,
		discloseMe = self.discloseMe
	}
	local args = self.args or {}
	local kwargs = self.kwargs or {}

	-- hack before sending
	pub_id = WUtils.encodeLuaInteger( pub_id )
	options = WUtils.encodeLuaTable( options )
	kwargs = WUtils.encodeLuaTable( kwargs )

	if self.kwargs then
		return { Publish.MESSAGE_TYPE, pub_id, options, self.topic, args, kwargs }
	elseif self.args then
		return { Publish.MESSAGE_TYPE, pub_id, options, self.topic, args }
	else
		return { Publish.MESSAGE_TYPE, pub_id, options, self.topic }
	end

end



--====================================================================--
--== Published Message Class
--====================================================================--


--[[
Format:
* `[PUBLISHED, PUBLISH.Request|id, Publication|id]`
--]]

Published = newClass( Message, {name="Published Message"} )

Published.MESSAGE_TYPE = 17  -- wamp message code

function Published:__new__( params )
	-- print( "Published:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type( params.request )=='number' )
	assert( type( params.publication )=='number' )

	self.request = params.request
	self.publication = params.publication

end

function Published.parse( wmsg )
	-- print( "Published.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Published.MESSAGE_TYPE )

	if #wmsg ~= 3 then
		error( WError.ProtocolError( "invalid length {0} for PUBLISHED" ) )
	end

	local request = check_or_raise_id{ value=wmsg[2], message="'request' in PUBLISHED" }
	local publication = check_or_raise_id{ value=wmsg[3], message="'publication' in PUBLISHED" }

	return Published{
		request=request,
		publication=publication
	}

end

function Published:marshal()
	-- print( "Published:marshal" )
	local request = WUtils.encodeLuaInteger( self.request )
	local publication = WUtils.encodeLuaInteger( self.publication )

	return { Published.MESSAGE_TYPE, request, publication }
end



--====================================================================--
--== Subscribe Message Class
--====================================================================--


--[[
Format: `[SUBSCRIBE, Request|id, Options|dict, Topic|uri]`
--]]

Subscribe = newClass( Message, {name="Subscribe Message"} )

Subscribe.MESSAGE_TYPE = 32  -- wamp message code

Subscribe.MATCH_EXACT = 'exact'
Subscribe.MATCH_PREFIX = 'prefix'
Subscribe.MATCH_WILDCARD = 'wildcard'

function Subscribe:__new__( params )
	-- print( "Subscribe:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.topic)=='string' )
	assert( params.match==nil or type(params.match)=='string' )
	assert( params.match==nil or Utils.propertyIn( { self.MATCH_EXACT, self.MATCH_PREFIX, self.MATCH_WILDCARD }, params.match ) )

	self.request = params.request
	self.topic = params.topic
	self.match = params.match

end


function Subscribe.parse( wmsg )
	-- print( "Subscribe.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Subscribe.MESSAGE_TYPE )

	if #wmsg ~= 4 then
		error( WError.ProtocolError( "wrong length, Subscribe" ) )
	end

	local request, options, topic

	request = check_or_raise_id{ value=wmsg[2], message="'request' in SUBSCRIBE" }
	options = check_or_raise_id{ value=wmsg[3], message="'options' in SUBSCRIBE" }
	topic = check_or_raise_id{ value=wmsg[4], message="'topic' in SUBSCRIBE" }

	return Subscribe{
		request=request,
		topic=topic,
		match=match,
	}

end


function Subscribe:marshal()
	-- print( "Subscribe:marshal" )

	local request = self.request
	local options = {
		match=self.match
	}

	-- hack before sending
	request = WUtils.encodeLuaInteger( request )
	options = WUtils.encodeLuaTable( options )

	return { Subscribe.MESSAGE_TYPE, request, options, self.topic }
end



--====================================================================--
--== Subscribed Message Class
--====================================================================--


--[[
Format: `[SUBSCRIBE, Request|id, Options|dict, Topic|uri]`
--]]

Subscribed = newClass( Message, {name="Subscribed Message"} )

Subscribed.MESSAGE_TYPE = 33  -- wamp message code

function Subscribed:__new__( params )
	-- print( "Subscribed:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.subscription)=='number' )

	self.request = params.request
	self.subscription = params.subscription

end


function Subscribed.parse( wmsg )
	-- print( "Subscribed.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Subscribed.MESSAGE_TYPE )

	if #wmsg ~= 3 then
		error( WError.ProtocolError( "wrong length, Subscribed" ) )
	end

	local request, subscription

	request = check_or_raise_id{ value=wmsg[2], message="'request' in SUBSCRIBED" }
	subscription = check_or_raise_id{ value=wmsg[3], message="'subscription' in SUBSCRIBED" }

	return Subscribed{
		request=request,
		subscription=subscription,
	}
end


function Subscribed:marshal()
	-- print( "Subscribed:marshal" )
	local request = WUtils.encodeLuaInteger( self.request )
	local subscription = WUtils.encodeLuaInteger( self.subscription )

	return { Subscribed.MESSAGE_TYPE, request, subscription }
end



--====================================================================--
--== Unsubscribe Message Class
--====================================================================--


--[[
Format: `[UNSUBSCRIBE, Request|id, SUBSCRIBED.Subscription|id]`
--]]

Unsubscribe = newClass( Message, {name="Unsubscribe Message"} )

Unsubscribe.MESSAGE_TYPE = 34  -- wamp message code

function Unsubscribe:__new__( params )
	-- print( "Unsubscribe:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.subscription)=='number' )

	self.request = params.request
	self.subscription = params.subscription

end


function Unsubscribe.parse( wmsg )
	-- print( "Unsubscribe.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Unsubscribe.MESSAGE_TYPE )

	if #wmsg ~= 3 then
		error( WError.ProtocolError( "wrong length, Unsubscribe" ) )
	end

	local request, subscription

	request = check_or_raise_id{ value=wmsg[2], message="'request' in SUBSCRIBE" }
	subscription = check_or_raise_id{ value=wmsg[3], message="'subscription' in SUBSCRIBE" }

	return Unsubscribe{
		request=request,
		subscription=subscription,
	}

end


function Unsubscribe:marshal()
	-- print( "Unsubscribe:marshal" )
	local request = WUtils.encodeLuaInteger( self.request )
	local subscription = WUtils.encodeLuaInteger( self.subscription )

	return { Unsubscribe.MESSAGE_TYPE, request, subscription }
end



--====================================================================--
--== Unsubscribed Message Class
--====================================================================--


Unsubscribed = newClass( Message, {name="Unsubscribed Message"} )

Unsubscribed.MESSAGE_TYPE = 35  -- wamp message code

function Unsubscribed:__new__( params )
	-- print( "Unsubscribed:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )

	self.request = params.request

end


function Unsubscribed.parse( wmsg )
	-- print( "Unsubscribed.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Unsubscribed.MESSAGE_TYPE )

	if #wmsg ~= 2 then
		error( WError.ProtocolError( "wrong length, Unsubscribed" ) )
	end

	local request = check_or_raise_id{ value=wmsg[2], message="'request' in UNSUBSCRIBED" }

	return Unsubscribed{
		request=request
	}

end


function Unsubscribed:marshal()
	-- print( "Unsubscribed:marshal" )
	local request = WUtils.encodeLuaInteger( self.request )

	return { Unsubscribed.MESSAGE_TYPE, request }
end



--====================================================================--
--== Event Message Class
--====================================================================--


--[[
Formats:
* `[EVENT, SUBSCRIBED.Subscription|id, PUBLISHED.Publication|id, Details|dict]`
* `[EVENT, SUBSCRIBED.Subscription|id, PUBLISHED.Publication|id, Details|dict, PUBLISH.Arguments|list]`
* `[EVENT, SUBSCRIBED.Subscription|id, PUBLISHED.Publication|id, Details|dict, PUBLISH.Arguments|list, PUBLISH.ArgumentsKw|dict]`
--]]

Event = newClass( Message, {name="Event Message"} )

Event.MESSAGE_TYPE = 36  -- wamp message code

function Event:__new__( params )
	-- print( "Event:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.subscription)=='number' )
	assert( type(params.publication)=='number' )
	assert( params.args==nil or type(params.args)=='table' )
	assert( params.kwargs==nil or type(params.kwargs)=='table' )
	assert( params.publisher==nil or type(params.publisher)=='number' )

	self.subscription = params.subscription
	self.publication = params.publication
	-- self.details = params.details
	self.args = params.args
	self.kwargs = params.kwargs
	self.publisher = params.publisher

end


function Event.parse( wmsg )
	-- print( "Event.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Event.MESSAGE_TYPE )

	if not Utils.propertyIn( { 4, 5, 6 }, #wmsg ) then
		error( WError.ProtocolError( "wrong length, EVENT" ) )
	end

	local subscription, publication, details
	local args, kwargs, publisher

	subscription = check_or_raise_id{ value=wmsg[2], message="'subscription' in SUBSCRIBE" }
	publication = check_or_raise_id{ value=wmsg[3], message="'publication' in SUBSCRIBE" }
	details = check_or_raise_extra{ value=wmsg[4], message="'details' in SUBSCRIBE" }


	if #wmsg > 4 then
		args = wmsg[5]
		if type(args) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'args' in EVENT" ) )
		end
	end

	if #wmsg > 5 then
		kwargs = wmsg[6]
		if type(kwargs) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'kwargs' in EVENT" ) )
		end
	end

	if details and details.publisher then
		publisher = details.publisher
		if type(publisher) ~= 'number' then
			error( WError.ProtocolError( "invalid type 'publisher' in EVENT" ) )
		end
	end

	return Event{
		subscription=subscription,
		publication=publication,
		details=details,
		args=args,
		kwargs=kwargs,
		publisher=publisher,
	}

end


function Event:marshal()
	-- print( "Event:marshal" )
	local details = {
		publisher = self.publisher
	}
	local args = self.args or {}
	local kwargs = self.kwargs or {}

	-- hack before sending
	details = WUtils.encodeLuaTable( details )
	kwargs = WUtils.encodeLuaTable( kwargs )

	if self.kwargs then
		return { Event.MESSAGE_TYPE, self.subscription, self.self.publication, details, args, kwargs }
	elseif self.args then
		return { Event.MESSAGE_TYPE, self.subscription, self.self.publication, details, args }
	else
		return { Event.MESSAGE_TYPE, self.subscription, self.self.publication, details }
	end

end



--====================================================================--
--== Call Message Class
--====================================================================--


--[[
Formats:
* `[CALL, Request|id, Options|dict, Procedure|uri]`
* `[CALL, Request|id, Options|dict, Procedure|uri, Arguments|list]`
* `[CALL, Request|id, Options|dict, Procedure|uri, Arguments|list, ArgumentsKw|dict]`
--]]

Call = newClass( Message, {name="Call Message"} )

Call.MESSAGE_TYPE = 48  -- wamp message code

function Call:__new__( params )
	-- print( "Call:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.procedure)=='string' )
	assert( params.args==nil or type(params.args)=='table' )
	assert( params.kwargs==nil or type(params.kwargs)=='table' )
	assert( params.timeout==nil or type(params.timeout)=='number' )
	assert( params.receive_progress==nil or type(params.receive_progress)=='boolean' )
	assert( params.discloseMe==nil or type(params.discloseMe)=='boolean' )

	self.request = params.request
	self.procedure = params.procedure
	self.args = params.args
	self.kwargs = params.kwargs
	self.timeout = params.timeout
	self.receive_progress = params.receive_progress
	self.discloseMe = params.discloseMe

end


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

	local req_id = self.request
	local args = self.args or {}
	local kwargs = self.kwargs or {}
	local options = {
		timeout = self.timeout,
		receive_progress = self.receive_progress,
		discloseMe = self.discloseMe
	}

	-- hack before sending
	req_id = WUtils.encodeLuaInteger( req_id )
	options = WUtils.encodeLuaTable( options )
	kwargs = WUtils.encodeLuaTable( kwargs )

	if self.kwargs then
		return { Call.MESSAGE_TYPE, req_id, options, self.procedure, args, kwargs }
	elseif self.args then
		return { Call.MESSAGE_TYPE, req_id, options, self.procedure, args }
	else
		return { Call.MESSAGE_TYPE, req_id, options, self.procedure }
	end

end



--====================================================================--
--== Cancel Message Class
--====================================================================--


-- Format: ``[CANCEL, CALL.Request|id, Options|dict]``

Cancel = newClass( Message, {name="Cancel Message"} )

Cancel.MESSAGE_TYPE = 49  -- wamp message code

Cancel.SKIP = 'skip'
Cancel.ABORT = 'abort'
Cancel.KILL = 'kill'


function Cancel:__new__( params )
	-- print( "Cancel:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( type( params.request )=='number' )
	assert( params.mode==nil or type(params.mode)=='string' )
	assert( Utils.propertyIn( { self.SKIP, self.ABORT, self.KILL }, params.mode ) )

	self.request = params.request
	self.mode = params.mode

end


--[[
parse() method not implemeneted because only necessary for routers
--]]
-- function Cancel:parse()
-- end


function Cancel:marshal()
	-- print( "Cancel:marshal" )

	local options = {
		mode = self.mode
	}

	-- hack before sending
	options = WUtils.encodeLuaTable( options )

	return { Cancel.MESSAGE_TYPE, self.request, options }
end



--====================================================================--
--== Result Message Class
--====================================================================--


--[[
Formats:
	* `[RESULT, CALL.Request|id, Details|dict]`
	* `[RESULT, CALL.Request|id, Details|dict, YIELD.Arguments|list]`
	* `[RESULT, CALL.Request|id, Details|dict, YIELD.Arguments|list, YIELD.ArgumentsKw|dict]`
--]]

Result = newClass( Message, {name="Result Message"} )

Result.MESSAGE_TYPE = 50  -- wamp message code

function Result:__new__( params )
	-- print( "Result:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( params.args==nil or type(params.args)=='table' )
	assert( params.kwargs==nil or type(params.kwargs)=='table' )
	assert( params.progress==nil or type(params.progress)=='boolean' )

	self.request = params.request
	self.args = params.args
	self.kwargs = params.kwargs
	self.progress = params.progress

end

function Result.parse( wmsg )
	-- print( "Result.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Result.MESSAGE_TYPE )

	if not Utils.propertyIn( { 3, 4, 5 }, #wmsg ) then
		error( WError.ProtocolError( "wrong length in RESULT" ) )
	end

	local request, details
	local args, kwargs, progress

	request = check_or_raise_id{ value=wmsg[2], message="'request' in SUBSCRIBE" }
	details = check_or_raise_extra{ value=wmsg[3], message="'details' in SUBSCRIBE" }

	if #wmsg > 3 then
		args = wmsg[4]
		if type(args) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'args' in EVENT" ) )
		end
	end

	if #wmsg > 4 then
		kwargs = wmsg[5]
		if type(kwargs) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'kwargs' in EVENT" ) )
		end
	end

	if details and details.progress then
		progress = details.progress
		if type(progress) ~= 'boolean' then
			error( WError.ProtocolError( "invalid type 'progress' in EVENT" ) )
		end
	end

	return Result{
		request=request,
		details=details,
		args=args,
		kwargs=kwargs,
		progress=progress
	}

end

function Result:marshal()
	-- print( "Result:marshal" )

	-- local options = {
	-- 	timeout = self._timeout,
	-- 	receive_progress = self._receive_progress,
	-- 	discloseMe = self._discloseMe
	-- }

	-- options = WUtils.encodeLuaTable( options )
	-- self._kwargs = WUtils.encodeLuaTable( self._kwargs )

	-- if self._kwargs then
	-- 	return { Result.MESSAGE_TYPE, self._request, options, self._procedure, self._args, self._kwargs }
	-- elseif self._args then
	-- 	return { Result.MESSAGE_TYPE, self._request, options, self._procedure, self._args }
	-- else
	-- 	return { Result.MESSAGE_TYPE, self._request, options, self._procedure }
	-- end
end



--====================================================================--
--== Register Message Class
--====================================================================--


--[[
Format:
* `[REGISTER, Request|id, Options|dict, Procedure|uri]`
--]]

Register = newClass( Message, {name="Register Message"} )

Register.MESSAGE_TYPE = 64  -- wamp message code

function Register:__new__( params )
	-- print( "Register:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.procedure)=='string' )
	assert( params.pkeys==nil or type(params.pkeys)=='table' )
	if params.pkeys then
		for _,v in ipairs( params.pkeys ) do
			assert( type(v)=='number' )
		end
	end
	assert( params.discloseCaller==nil or type(params.discloseCaller)=='boolean' )
	assert( params.discloseCallerTransport==nil or type(params.discloseCallerTransport)=='boolean' )

	self.request = params.request
	self.procedure = params.procedure
	self.pkeys = params.pkeys
	self.discloseCaller = params.discloseCaller
	self.discloseCallerTransport = params.discloseCallerTransport

end


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
	-- print( "Register:marshal" )

	local options = {
		pkeys = self.pkeys,
		discloseCaller = self.discloseCaller,
		discloseCallerTransport = self.discloseCallerTransport,
	}
	local req_id = self.request

	-- hack before sending
	req_id = WUtils.encodeLuaInteger( req_id )
	options = WUtils.encodeLuaTable( options )

	return { Register.MESSAGE_TYPE, req_id, options, self.procedure }
end



--====================================================================--
--== Registered Message Class
--====================================================================--


--[[
Format:
* `[REGISTERED, REGISTER.Request|id, Registration|id]`
--]]

Registered = newClass( Message, {name="Registered Message"} )

Registered.MESSAGE_TYPE = 65  -- wamp message code

function Registered:__new__( params )
	-- print( "Registered:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.registration)=='number' )

	self.request = params.request
	self.registration = params.registration

end


-- Static function
function Registered.parse( wmsg )
	-- print( "Registered.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Registered.MESSAGE_TYPE )

	if #wmsg ~= 3 then
		error( WError.ProtocolError( "wrong length in REGISTERED" ) )
	end

	local request, registration

	request = check_or_raise_id{ value=wmsg[2], message="'request' in REGISTERED" }
	registration = check_or_raise_id{ value=wmsg[3], message="'registration' in REGISTERED" }

	return Registered{
		request=request,
		registration=registration
	}

end


-- function Registered:marshal()
-- 	print( "Registered:marshal" )

-- 	local options = {
-- 		pkeys = self.pkeys,
-- 		discloseCaller = self.discloseCaller,
-- 	}

-- 	options = WUtils.encodeLuaTable( options )
-- 	self.kwargs = WUtils.encodeLuaTable( self.kwargs )

-- 	return { Registered.MESSAGE_TYPE, self.request, options, self.procedure }
-- end



--====================================================================--
--== Unregister Message Class
--====================================================================--


--[[
Format:
* `[UNREGISTER, Request|id, REGISTERED.Registration|id]`
--]]

Unregister = newClass( Message, {name="Unregister Message"} )

Unregister.MESSAGE_TYPE = 66  -- wamp message code

function Unregister:__new__( params )
	-- print( "Unregister:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.registration)=='number' )

	self.request = params.request
	self.registration = params.registration -- id

end


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
	-- print( "Unregister:marshal" )

	local req_id = WUtils.encodeLuaInteger( self.request )
	local reg_id = WUtils.encodeLuaInteger( self.registration )

	return { Unregister.MESSAGE_TYPE, req_id, reg_id }
end



--====================================================================--
--== Unregistered Message Class
--====================================================================--


Unregistered = newClass( Message, {name="Unregistered Message"} )

Unregistered.MESSAGE_TYPE = 67  -- wamp message code

function Unregistered:__new__( params )
	-- print( "Unregistered:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )

	self.request = params.request

end


-- Static function
function Unregistered.parse( wmsg )
	-- print( "Unregistered.parse", wmsg )

	-- Sanity Check
	assert( #wmsg > 0 and wmsg[1] == Unregistered.MESSAGE_TYPE )

	if #wmsg ~= 2 then
		error( WError.ProtocolError( "wrong length in UNREGISTERED" ) )
	end

	local request = check_or_raise_id{ value=wmsg[2], message="'request' in REGISTERED" }

	return Unregistered{
		request=request
	}

end


-- function Unregistered:marshal()
-- 	print( "Unregistered:marshal" )

-- 	local options = {
-- 		pkeys = self.pkeys,
-- 		discloseCaller = self.discloseCaller,
-- 	}

-- 	options = WUtils.encodeLuaTable( options )
-- 	self.kwargs = WUtils.encodeLuaTable( self.kwargs )

-- 	return { Unregistered.MESSAGE_TYPE, self.request, options, self.procedure }
-- end



--====================================================================--
--== Invocation Message Class
--====================================================================--


--[[
Formats:
* `[INVOCATION, Request|id, REGISTERED.Registration|id, Details|dict]`
* `[INVOCATION, Request|id, REGISTERED.Registration|id, Details|dict, CALL.Arguments|list]`
* `[INVOCATION, Request|id, REGISTERED.Registration|id, Details|dict, CALL.Arguments|list, CALL.ArgumentsKw|dict]`
--]]

Invocation = newClass( Message, {name="Invocation Message"} )

Invocation.MESSAGE_TYPE = 68  -- wamp message code

function Invocation:__new__( params )
	-- print( "Invocation:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	assert( type(params.request)=='number' )
	assert( type(params.registration)=='number' )
	assert( params.args==nil or type(params.args)=='table' )
	assert( params.kwargs==nil or type(params.kwargs)=='table' )
	assert( params.timeout==nil or type(params.timeout)=='number' )
	assert( params.receive_progress==nil or type(params.receive_progress)=='boolean' )
	assert( params.caller==nil or type(params.caller)=='number' )
	assert( params.caller_transport==nil or type(params.caller_transport)=='table' )
	assert( params.authid==nil or type(params.authid)=='string' )
	assert( params.authrole==nil or type(params.authrole)=='string' )
	assert( params.authmethod==nil or type(params.authmethod)=='string' )

	self.request = params.request
	self.registration = params.registration
	self.args = params.args
	self.kwargs = params.kwargs
	self.timeout = params.timeout
	self.receive_progress = params.receive_progress
	self.caller = params.caller
	self.caller_transport = params.caller_transport
	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod

end


-- Static function
function Invocation.parse( wmsg )
	-- print( "Invocation.parse", wmsg )

	assert( #wmsg > 0 and wmsg[1] == Invocation.MESSAGE_TYPE )

	if not Utils.propertyIn( { 4, 5, 6 }, #wmsg ) then
		error( WError.ProtocolError( "wrong length in INVOCATION" ) )
	end

	local request, registration, details
	local args, kwargs
	local timeout, receive_progress, caller, caller_transport
	local authid, authrole, authmethod

	request = check_or_raise_id{ value=wmsg[2], message="'request' in INVOCATION" }
	registration = check_or_raise_id{ value=wmsg[3], message="'registration' in INVOCATION" }
	details = check_or_raise_extra{ value=wmsg[4], message="'details' in INVOCATION" }

	if #wmsg > 4 then
		args = wmsg[5]
		if type(args) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'args' in INVOCATION" ) )
		end
	end

	if #wmsg > 5 then
		kwargs = wmsg[6]
		if type(kwargs) ~= 'table' then
			error( WError.ProtocolError( "invalid type 'kwargs' in INVOCATION" ) )
		end
	end


	if details and details.timeout then
		timeout = details.timeout
		if type(timeout) ~= 'boolean' then
			error( WError.ProtocolError( "invalid type 'timeout' in INVOCATION" ) )
		end
	end

	if details and details.receive_progress then
		receive_progress = details.receive_progress
		if type(receive_progress) ~= 'boolean' then
			error( WError.ProtocolError( "invalid type 'receive_progress' in INVOCATION" ) )
		end
	end

	if details and details.caller then
		caller = details.caller
		if type(caller) ~= 'number' then
			error( WError.ProtocolError( "invalid type 'caller' in INVOCATION" ) )
		end
	end

	if details and details.caller_transport then
		caller_transport = details.caller_transport
		if type(caller_transport) ~= 'number' then
			error( WError.ProtocolError( "invalid type 'caller_transport' in INVOCATION" ) )
		end
	end

	if details and details.authid then
		authid = details.authid
		if type(authid) ~= 'string' then
			error( WError.ProtocolError( "invalid type 'authid' in INVOCATION" ) )
		end
	end

	if details and details.authrole then
		authrole = details.authrole
		if type(authrole) ~= 'string' then
			error( WError.ProtocolError( "invalid type 'authrole' in INVOCATION" ) )
		end
	end

	if details and details.authmethod then
		authmethod = details.authmethod
		if type(authmethod) ~= 'string' then
			error( WError.ProtocolError( "invalid type 'authmethod' in INVOCATION" ) )
		end
	end


	return Invocation{
		request=request,
		registration=registration,
		args=args,
		kwargs=kwargs,
		timeout=timeout,
		caller=caller,
		caller_transport=caller_transport,
		authid=authid,
		authrole=authrole,
		authmethod=authmethod
	}

end


-- function Invocation:marshal()
-- 	print( "Invocation:marshal" )

-- 	local options = {
-- 		pkeys = self.pkeys,
-- 		discloseCaller = self.discloseCaller,
-- 	}

-- 	options = WUtils.encodeLuaTable( options )
-- 	self.kwargs = WUtils.encodeLuaTable( self.kwargs )

-- 	return { Invocation.MESSAGE_TYPE, self.request, options, self.procedure }
-- end



--====================================================================--
--== Interrupt Message Class
--====================================================================--



-- Format: ``[INTERRUPT, CALL.Request|id, Options|dict]``

Interrupt = newClass( Message, {name="Interrupt Message"} )

Interrupt.MESSAGE_TYPE = 69  -- wamp message code

Interrupt.ABORT = 'abort'
Interrupt.KILL = 'kill'


function Interrupt:__new__( params )
	-- print( "Interrupt:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( type( params.request )=='number' )
	assert( params.mode==nil or type(params.mode)=='string' )
	assert( Utils.propertyIn( { self.ABORT, self.KILL }, params.mode ) )

	self.request = params.request
	self.mode = params.mode

end


--[[
parse() method not implemeneted because only necessary for routers
--]]
-- function Interrupt:parse()
-- end


function Interrupt:marshal()
	-- print( "Interrupt:marshal" )

	local req_id = self.request
	local options = {
		mode=self.mode
	}

	-- hack before sending
	req_id = WUtils.encodeLuaInteger( req_id )
	options = WUtils.encodeLuaTable( options )

	return { Interrupt.MESSAGE_TYPE, req_id, options }
end



--====================================================================--
--== Yield Message Class
--====================================================================--


--[[
Format:
* `[YIELD, INVOCATION.Request|id, Options|dict]`
* `[YIELD, INVOCATION.Request|id, Options|dict, Arguments|list]`
* `[YIELD, INVOCATION.Request|id, Options|dict, Arguments|list, ArgumentsKw|dict]`
--]]

Yield = newClass( Message, {name="Yield Message"} )

Yield.MESSAGE_TYPE = 70  -- wamp message code

function Yield:__new__( params )
	-- print( "Yield:__new__" )
	params = params or {}
	self:superCall( "__new__", params )
	--==--

	assert( type(params.request)=='number' )
	assert( params.args==nil or type(params.args)=='table' )
	assert( params.kwargs==nil or type(params.kwargs)=='table' )
	assert( params.progress==nil or type(params.progress)=='boolean' )

	self.request = params.request
	self.args = params.args
	self.kwargs = params.kwargs
	self.progress = params.progress

end


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
	-- print( "Yield:marshal" )

	local req_id = self.request
	local args = self.args or {}
	local kwargs = self.kwargs or {}
	local options = {
		progress = self.progress,
	}

	-- hack before sending
	req_id = WUtils.encodeLuaInteger( req_id )
	options = WUtils.encodeLuaTable( options )
	kwargs = WUtils.encodeLuaTable( kwargs )

	if self.kwargs then
		return { Yield.MESSAGE_TYPE, req_id, options, args, kwargs }
	elseif self.args then
		return { Yield.MESSAGE_TYPE, req_id, options, args }
	else
		return { Yield.MESSAGE_TYPE, req_id, options }
	end
end



--====================================================================--
--== Message Export
--====================================================================--


local MessageExport = {}

--== Class References

MessageExport.Hello = Hello
MessageExport.Welcome = Welcome
MessageExport.Abort = Abort
MessageExport.Challenge = Challenge
MessageExport.Authenticate = Authenticate
MessageExport.Goodbye = Goodbye
MessageExport.Heartbeat = Heartbeat
MessageExport.Error = Error
MessageExport.Publish = Publish
MessageExport.Published = Published
MessageExport.Subscribe = Subscribe
MessageExport.Subscribed = Subscribed
MessageExport.Unsubscribe = Unsubscribe
MessageExport.Unsubscribed = Unsubscribed
MessageExport.Event = Event
MessageExport.Call = Call
MessageExport.Cancel = Cancel
MessageExport.Result = Result
MessageExport.Register = Register
MessageExport.Registered = Registered
MessageExport.Unregister = Unregister
MessageExport.Unregistered = Unregistered
MessageExport.Invocation = Invocation
MessageExport.Interrupt = Interrupt
MessageExport.Yield = Yield

--== Type-Class Mapping

MessageExport.map = {
	[Hello.MESSAGE_TYPE] = Hello,
	[Welcome.MESSAGE_TYPE] = Welcome,
	[Abort.MESSAGE_TYPE] = Abort,
	[Challenge.MESSAGE_TYPE] = Challenge,
	[Authenticate.MESSAGE_TYPE] = Authenticate,
	[Goodbye.MESSAGE_TYPE] = Goodbye,
	[Heartbeat.MESSAGE_TYPE] = Heartbeat,
	[Error.MESSAGE_TYPE] = Error,
	[Publish.MESSAGE_TYPE] = Publish,
	[Published.MESSAGE_TYPE] = Published,
	[Subscribe.MESSAGE_TYPE] = Subscribe,
	[Subscribed.MESSAGE_TYPE] = Subscribed,
	[Unsubscribe.MESSAGE_TYPE] = Unsubscribe,
	[Unsubscribed.MESSAGE_TYPE] = Unsubscribed,
	[Event.MESSAGE_TYPE] = Event,
	[Call.MESSAGE_TYPE] = Call,
	[Cancel.MESSAGE_TYPE] = Cancel,
	[Result.MESSAGE_TYPE] = Result,
	[Register.MESSAGE_TYPE] = Register,
	[Registered.MESSAGE_TYPE] = Registered,
	[Unregister.MESSAGE_TYPE] = Unregister,
	[Unregistered.MESSAGE_TYPE] = Unregistered,
	[Invocation.MESSAGE_TYPE] = Invocation,
	[Interrupt.MESSAGE_TYPE] = Interrupt,
	[Yield.MESSAGE_TYPE] = Yield,
}


return MessageExport

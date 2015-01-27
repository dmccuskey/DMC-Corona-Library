--====================================================================--
-- dmc_wamp/protocol.lua
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

--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]



--====================================================================--
--== DMC Corona Library : DMC WAMP Protocol
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local json = require 'json'

local Objects = require 'lib.dmc_lua.lua_objects'
local Patch = require 'lib.dmc_lua.lua_patch'
local LuaEventsMixin = require 'lib.dmc_lua.lua_events_mix'
local Utils = require 'lib.dmc_lua.lua_utils'

local WError = require 'dmc_wamp.exception'
local WFutureMixin = require 'dmc_wamp.future_mix'
local WMessageFactory = require 'dmc_wamp.message'
local WRole = require 'dmc_wamp.role'
local WTypes = require 'dmc_wamp.types'
local WUtils = require 'dmc_wamp.utils'



--====================================================================--
--== Setup, Constants


Patch.addPatch( 'table-pop' )

local EventsMix = LuaEventsMixin.EventsMix
local FutureMix = WFutureMixin.FutureMix

-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local Class = Objects.Class

local tpop = table.pop



--====================================================================--
--== Endpoint Class
--====================================================================--


--[[
--]]

local Endpoint = newClass( nil, {name="Endpoint"} )

function Endpoint:__new__( params )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.obj )
	assert( params.fn )
	assert( params.procedure )

	self.obj = params.obj
	self.fn = params.fn
	self.procedure = params.procedure
	self.options = params.options
end



--====================================================================--
--== Handler Class
--====================================================================--


--[[
--]]

local Handler = newClass( nil, {name="Handler"} )

function Handler:__new__( params )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.fn )
	assert( params.topic )

	self.obj = params.obj
	self.fn = params.fn
	self.topic = params.topic
	self.details_arg = params.details_arg

	-- this addition is for more Corona-ism
	-- used in added unsubscribe() method to Session
	self.subscription = params.subscription

end



--====================================================================--
--== Publication Class
--====================================================================--


--[[
Object representing a publication.
This class implements :class:`autobahn.wamp.interfaces.IPublication`.
--]]

local Publication = newClass( nil, {name="Publication"} )

function Publication:__new__( params )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.publication_id )

	self.id = params.publication_id
end



--====================================================================--
--== Subscription Class
--====================================================================--


--[[
Object representing a subscription.
This class implements :class:`autobahn.wamp.interfaces.ISubscription`.
--]]

local Subscription = newClass( nil, {name="Subscription"} )

function Subscription:__new__( params )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.session )
	assert( params.subscription_id )

	self._session = params.session
	self.id = params.subscription_id
	self.active = true
end

-- Implements :func:`autobahn.wamp.interfaces.ISubscription.unsubscribe`
--
function Subscription:unsubscribe()
	-- print( "Subscription:unsubscribe" )
	return self._session:_unsubscribe( self )
end



--====================================================================--
--== Registration Class
--====================================================================--


--[[
Object representing a registration.
This class implements :class:`autobahn.wamp.interfaces.IRegistration`.
--]]

local Registration = newClass( nil, {name="Registration"} )

function Registration:__new__( params )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.session )
	assert( params.registration_id )

	self._session = params.session
	self.id = params.registration_id
	self.active = true

	-- this is a shortcut i put in the code
	-- autobahn handles it another way
	self.endpoint = params.endpoint
end

-- Implements :func:`autobahn.wamp.interfaces.IRegistration.unregister`
--
function Registration:unregister()
	-- print( "Registration:unregister" )
	return self._session:_unregister( self )
end



--====================================================================--
--== Base Session Class
--====================================================================--


--[[
WAMP session base class.

This class implements:

:class:`autobahn.wamp.interfaces.ISession`
--]]

local BaseSession = newClass( { Class, EventsMix }, {name="Base Session"} )

function BaseSession:__new__( params )
	params = params or {}
	Class.__new__( self, params )
	EventsMix.__init__( self, params )
	--==--

	--== Create Properties ==--

	-- for library-level debugging
	self.debug = false

	-- this is for app level debugging. exceptions raised in user code
	-- will get logged (that is, when invoking remoted procedures or
	-- when invoking event handlers)
	self.debug_app = false

	-- this is for marshalling traceback from exceptions thrown in user
	-- code within WAMP error messages (that is, when invoking remoted
	-- procedures)
	self.traceback_app = false

	-- mapping of exception classes to WAMP error URIs
	self._ecls_to_uri_pat = {}

	-- mapping of WAMP error URIs to exception classes
	self._uri_to_ecls = {}

	-- session authentication information
	self._authid = None
	self._authrole = None
	self._authmethod = None
	self._authprovider = None

end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onConnect`
--
function BaseSession:onConnect()
	-- print( "BaseSession:onConnect" )
	--==--
end

-- Implements :func:`autobahn.wamp.interfaces.ISession.onJoin`
--
function BaseSession:onJoin( params )
	-- print( "BaseSession:onJoin" )
	--==--
end

-- Implements :func:`autobahn.wamp.interfaces.ISession.onLeave`
--
function BaseSession:onLeave( params )
	-- print( "BaseSession:onLeave" )
	--==--
end

-- Implements :func:`autobahn.wamp.interfaces.ISession.onDisconnect`
--
function BaseSession:onDisconnect()
	-- print( "BaseSession:onDisconnect" )
	--==--
end

-- Implements :func:`autobahn.wamp.interfaces.ISession.define`
--
function BaseSession:define( params )
	-- print( "BaseSession:define" )
	--==--
	-- TODO: fill this out
end

-- Create a WAMP error message from an exception
--
function BaseSession:_message_from_exception( params )
	-- print( "BaseSession:_message_from_exception" )
	--==--
	-- TODO: fill this out
end

-- Create a user (or generic) exception from a WAMP error message
--
function BaseSession:_exception_from_message( params )
	-- print( "BaseSession:_exception_from_message" )
	--==--
	-- TODO: fill this out
end



--====================================================================--
--== Application Session Class
--====================================================================--


--[[
WAMP endpoint session.

This class implements:
* :class:`autobahn.wamp.interfaces.IPublisher`
* :class:`autobahn.wamp.interfaces.ISubscriber`
* :class:`autobahn.wamp.interfaces.ICaller`
* :class:`autobahn.wamp.interfaces.ICallee`

?? * :class:`autobahn.wamp.interfaces.ITransportHandler`
--]]

local Session = newClass( { BaseSession, FutureMix }, { name="WAMP Session" } )

--== Event Constants ==--

Session.EVENT = 'wamp_session_event'

Session.ONJOIN = 'on_join_wamp_event'
Session.ONCHALLENGE = 'on_challenge_wamp_event'


--======================================================--
-- Start: Setup DMC Objects

function Session:__new__( params )
	-- print( "Session:__new__" )
	params = params or {}
	BaseSession.__new__( self, params )
	FutureMix.__init__( self, params )
	--==--

	--== Create Properties ==--

	-- realm, authid, authmethods
	self.config = params.config or WTypes.ComponentConfig{ realm='default' }

	self._transport = nil
	self._session_id = nil
	self._realm = nil

	self._session_id = nil
	self._goodbye_sent = nil
	self._transport_is_closing = nil

	-- outstanding requests
	self._publish_reqs = {}
	self._subscribe_reqs = {}
	self._unsubscribe_reqs = {}
	self._call_reqs = {}
	self._register_reqs = {}
	self._unregister_reqs = {}

	-- subscriptions in place
	self._subscriptions = {}

	-- registrations in place
	self._registrations = {}

	-- incoming invocations
	self._invocations = {}

end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


-- Implements :func:`autobahn.wamp.interfaces.ITransportHandler.onOpen`
--
function Session:onOpen( params )
	-- print( "Session:onOpen" )
	params = params or {}
	--==--
	assert( params.transport )

	self._transport = params.transport
	self:onConnect()
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onConnect`
--
function Session:onConnect()
	-- print( "Session:onConnect" )

	self:join{ realm=self.config.realm, authid=self.config.authid, authmethods=self.config.authmethods }
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.join`
-- :params:
-- realm
-- authmethods
-- authid
--
function Session:join( params )
	-- print( "Session:join", params, params.authid )
	params = params or {}
	--==--

	assert( type( params.realm ) == 'string' )
	assert( params.authid == nil or type( params.authid ) == 'string' )
	assert( params.authmethods == nil or type( params.authmethods ) == 'table' )

	if self._session_id then error( "Session:join :: already joined" ) end

	local roles, msg

	self._goodbye_sent = false

	roles = {
		WRole.RolePublisherFeatures(),
		WRole.RoleSubscriberFeatures({publication_trustlevels=true}),
		WRole.RoleCallerFeatures(),
		WRole.RoleCalleeFeatures()
	}

	msg = WMessageFactory.Hello{
		realm=params.realm,
		roles=roles,
		authmethods=params.authmethods,
		authid=params.authid
	}
	self._realm = params.realm
	self._transport:send( msg )
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.disconnect`
--
function Session:disconnect( details )
	-- print( "Session:disconnect" )
	if self._transport then
		self._transport:close( details.reason, details.message )
	else
		-- transport not available
		error( "Session:disconnect :: transport not available" )
	end
end


-- Implements :func:`autobahn.wamp.interfaces.ITransportHandler.onMessage`
--
function Session:onMessage( msg )
	-- print( "Session:onMessage", msg )

	if self._session_id == nil then

		-- the first message must be WELCOME, ABORT or CHALLENGE ..
		--
		if msg:isa( WMessageFactory.Welcome ) then
			self._session_id = msg.session

			local details

			details = WTypes.SessionDetails{
				realm=self._realm,
				session=self._session_id,
				authid=msg.authid,
				authrole=msg.authrole,
				authmethod=msg.authmethod,
				authprovider=msg.authprovider -- this is missing from autobahn
			}

			-- don't know why Autobahn has this as a future
			-- self:_as_future( self.onJoin, { details } )
			-- changing to regular method call (like was in earlier release)

			self:onJoin( details )


		elseif msg:isa( WMessageFactory.Abort ) then

			self:onLeave( WTypes.CloseDetails{ reason=msg.reason, message=msg.message } )


		elseif msg:isa( WMessageFactory.Challenge ) then

			local challenge, def
			local success_f, failure_f
			local onChallenge_f = self.config.onchallenge

			if type( onChallenge_f ) ~= 'function' then
				error( WError.ProtocolError( "Received %s incorrect onChallenge" % 'fdsf' ) )
			end

			challenge = WTypes.Challenge{
				method=msg.method,
				extra=msg.extra
			}

			def = self:_as_future( onChallenge_f, { challenge } )

			success_f = function( signature )
				-- print( "Challenge: success callback", signature )
				local reply = WMessageFactory.Authenticate{
					signature = signature,
				}
				self._transport:send( reply )
			end
			failure_f = function( err )
				-- print( "Challenge: failure callback" )
			end

			self:_add_future_callbacks( def, success_f, failure_f )


		else
			error( WError.ProtocolError( "Received %s message, and session is not yet established" % msg.NAME ) )
		end

		return
	end


	--== Goodbye Message

	if msg:isa( WMessageFactory.Goodbye ) then

		if not self._goodbye_sent then
			local reply = WMessageFactory.Goodbye:new()
			self._transport:send( reply )
		end

		self._session_id = nil
		self:onLeave( WTypes.CloseDetails( { reason=msg.reason, message=msg.message  } ))


	--== Event Message

	elseif msg:isa( WMessageFactory.Event ) then

		if not self._subscriptions[ msg.subscription ] then
			error( WError.ProtocolError( "EVENT received for non-subscribed subscription ID" ) )
		end

		local handler = self._subscriptions[ msg.subscription ]

		-- TODO: event details

		local evt = {
			args=msg.args,
			kwargs=msg.kwargs
		}
		if handler.obj then
			handler.fn( handler.obj, evt )
		else
			handler.fn( evt )
		end

		-- TODO: exception handling


	--== Published Message

	elseif msg:isa( WMessageFactory.Published ) then

		if not self._publish_reqs[ msg.request ] then
			error( WError.ProtocolError( "PUBLISHED received for non-pending request ID" ) )
			return
		end

		local pub_req = tpop( self._publish_reqs, msg.request )
		local def, opts = unpack( pub_req )
		local pub = Publication:new{ publication=msg.publication }

		self:_resolve_future( def, pub )


	--== Subscribed Message

	elseif msg:isa( WMessageFactory.Subscribed ) then
		-- print("onMessage:Subscribed")

		if not self._subscribe_reqs[ msg.request ] then
			error( WError.ProtocolError( "SUBSCRIBED received for non-pending request ID" ) )
			return
		end

		local sub_req = tpop( self._subscribe_reqs, msg.request )
		local def, obj, func, topic, options = unpack( sub_req )

		local sub = Subscription:new{
			session=self,
			subscription_id=msg.subscription
		}

		self._subscriptions[ msg.subscription ] = Handler:new{
			obj=obj,
			fn=func,
			topic=topic,
			details_arg=options.details_arg,
			subscription=sub
		}

		self:_resolve_future( def, sub )


	--== Unsubscribed Message

	elseif msg:isa( WMessageFactory.Unsubscribed ) then

		if not self._unsubscribe_reqs[ msg.request ] then
			error( WError.ProtocolError( "UNSUBSCRIBED received for non-pending request ID" ) )
			return
		end

		local unsub_req = tpop( self._unsubscribe_reqs, msg.request )
		local def, sub = unpack( unsub_req )

		self._subscriptions[sub.id] = nil
		sub.active = false

		self:_resolve_future( def )


	--== Result Message

	elseif msg:isa( WMessageFactory.Result ) then

		if not self._call_reqs[ msg.request ] then
			error( WError.ProtocolError( "RESULT received for non-pending request ID" ) )
			return
		end

		-- Progress
		--
		if msg.progress then
			local _, opts = self._call_reqs[ msg.request ]
			if opts.onProgress then
				opts.onProgress( msg.args, msg.kwargs )
			end

		-- Result
		--
		else
			local call_req = tpop( self._call_reqs, msg.request )
			local def, opts = unpack( call_req )

			if not msg.args and not msg.kwargs then
				self:_resolve_future( def, nil )
			else
				local res = WTypes.CallResult:new{
					results=msg.args,
					kwresults=msg.kwargs
				}

				self:_resolve_future( def, res )
			end

		end


	--== Invocation Message

	elseif msg:isa( WMessageFactory.Invocation ) then

		if self._invocations[ msg.request ] then
			error( WError.ProtocolError( "Invocation: already received request for this id" ) )
			return
		end

		if not self._registrations[ msg.registration ] then
			error( WError.ProtocolError( "Invocation: don't have this registration ID" ) )
			return
		end

		local registration = self._registrations[ msg.registration ]
		local endpoint = registration.endpoint

		-- TODO: implement Call Details
		-- if endpoint.options and endpoint.options.details_arg then
		-- 	msg.kwargs = msg.kwargs or {}

		-- 	if msg.receive_progress then
		-- 	else
		-- 	end
		-- end

		local def_params, def, def_func
		local success_f, failure_f

		if not endpoint.obj then
			def_func = endpoint.fn
		else
			def_func = function( ... )
				endpoint.fn( endpoint.obj, ... )
			end
		end
		def = self:_as_future( def_func, msg.args, msg.kwargs )

		success_f = function( res )
			-- print("Invocation: success callback")
			self._invocations[ msg.request ] = nil

			local reply = WMessageFactory.Yield:new{
				request = msg.request,
				args = res.results,
				kwargs = res.kwresults
			}
			self._transport:send( reply )

		end
		failure_f = function( err )
			-- print("Invocation: failure callback")
			self._invocations[ msg.request ] = nil
		end

		self._invocations[ msg.request ] = def
		self:_add_future_callbacks( def, success_f, failure_f )


	--== Interrupt Message

	elseif msg:isa( WMessageFactory.Interrupt ) then
		error( "not implemented" )


	--== Registered Message

	elseif msg:isa( WMessageFactory.Registered ) then

		if not self._register_reqs[ msg.request ] then
			error( WError.ProtocolError( "REGISTERED received for non-pending request ID" ) )
		end

		local reg_req = tpop( self._register_reqs, msg.request )

		local obj, fn, procedure, options = unpack( reg_req )

		local endpoint = Endpoint:new{
			obj=obj,
			fn=fn,
			procedure=procedure,
			options=options
		}

		self._registrations[ msg.registration ] = Registration:new{
			session=self,
			registration_id=msg.registration,
			endpoint=endpoint
		}


	--== Unregistered Message

	elseif msg:isa( WMessageFactory.Unregistered ) then

		if not self._unregister_reqs[ msg.request ] then
			error( WError.ProtocolError( "UNREGISTERED received for non-pending request ID" ) )
		end

		local unreg_req = tpop( self._unregister_reqs, msg.request )
		local def, registration = unpack( unreg_req )

		self._registrations[ registration.id ] = nil
		registration.active = false
		self:_resolve_future( def, nil )


	--== Unregistered Message

	elseif msg:isa( WMessageFactory.Error ) then


	--== Unregistered Message

	elseif msg:isa( WMessageFactory.Heartbeat ) then


	else
		if onError then onError( "unknown message class", msg:class().NAME ) end

	end

end


-- Implements :func:`autobahn.wamp.interfaces.ITransportHandler.onClose`
--
function Session:onClose( msg, onError )
	-- print( "Session:onClose" )

	self._transport = nil

	if self._session_id then
		self:onLeave()
		self._session_id = nil
	end

	self:onDisconnect()

end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onChallenge`
--[[
https://github.com/crossbario/crossbar/wiki/WAMP%20CRA%20Authentication
this page has a totally different way of dealing with onChallenge
the JavaScript frontend example shows onChallenge being passed in
from there as a function
--]]
--
-- function Session:onChallenge( challenge )
-- 	print( "Session:onChallenge", challenge, self )
-- end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onJoin`
--
function Session:onJoin( details )
	-- print( "Session:onJoin", details )
	self:dispatchEvent( self.ONJOIN, {details=details} )
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onLeave`
-- @param details type.SessionDetails
function Session:onLeave( details )
	-- print( "Session:onLeave" )
	self:disconnect( details )
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.leave`
--
function Session:leave( params )
	-- print( "Session:leave" )
	params = params or {}
	params.reason = params.reason or 'wamp.close.normal'
	--==--

	if not self._session_id then
		error( "not joined" ); return
	end

	if self._goodbye_sent then
			error( "Already requested to close the session" )

	else
		local msg = WMessageFactory.Goodbye:new( params )
		self._transport:send( msg )
		self._goodbye_sent = true

	end
end


-- Implements :func:`autobahn.wamp.interfaces.IPublisher.publish`
--
function Session:publish( topic, params )
	-- print( "Session:publish" )
	params = params or {}
	--==--

	assert( topic )

	if not self._transport then
		error( WError.TransportError() )
	end

	local opts = params.options or {}
	local request = WUtils.id()
	local msg, p
	p = {
		request=request,
		topic=topic,
		args=params.args,
		kwargs=params.kwargs
	}
	-- layer in Publish message options
	if opts.options then
		p = Utils.extend( opts.options, p )
	end

	msg = WMessageFactory.Publish:new( p )

	if opts.acknowledge == true then
		local def = self:_create_future()
		self._publish_reqs[ request ] = { def, opts }
		self._transport:send( msg )
		return def
	else
		self._transport:send( msg )
		return
	end

end


-- Implements :func:`autobahn.wamp.interfaces.ISubscriber.subscribe`
--
function Session:subscribe( topic, handler, params )
	-- print( "Session:subscribe", topic, handler, params )
	params = params or {}
	--==--
	assert( topic )

	if not self._transport then
		error( WError.TransportLostError() )
	end

	-- TODO: register on object
	-- TODO: change onEvent, onSubscribe ? add params to array

	local function _subscribe(obj, handler, topic, prms)
		local request, def, msg

		request = WUtils.id()
		def = self:_create_future()
		self._subscribe_reqs[ request ] = { def, obj, handler, topic, prms }

		msg = WMessageFactory.Subscribe:new{
			request=request,
			topic=topic,
			options=prms.options
		}
		self._transport:send( msg )

		return def
	end

	if type(handler)=='function' then
		return _subscribe( nil, handler, topic, params )
	else
		error( "to be implemented" )
	end


end


--[[
This is an addition specifically for Corona SDK
it's more of a Corona-ism
--]]
function Session:unsubscribe( topic, callback )
	-- print( "Session:unsubscribe", topic, callback )

	for _, handler in pairs( self._subscriptions ) do
		if handler.topic == topic and handler.fn == callback then
			handler.subscription:unsubscribe()
			break
		end
	end

end


-- Called from :meth:`autobahn.wamp.protocol.Subscription.unsubscribe`
--
function Session:_unsubscribe( subscription )
	-- print( "Session:_unsubscribe", subscription )
	--==--
	assert( subscription:isa( Subscription ) )
	assert( subscription.active )
	assert( self._subscriptions[subscription.id]~=nil )

	if not self._transport then
		error( WError.TransportLostError() )
	end

	local def, request, msg

	request = WUtils.id()
	def = self:_create_future()

	self._unsubscribe_reqs[request] = { def, subscription }

	msg = WMessageFactory.Unsubscribe:new{
		request=request,
		subscription=subscription.id
	}
	self._transport:send( msg )

	return def

end


function Session:call( procedure, params )
	-- print( "Session:call", procedure )
	params = params or {}
	--==--

	assert( type(procedure)=='string' )

	if not self._transport then
		error( WError.TransportLostError() )
	end

	local opts = params.options or {}
	local def, request, msg, p

	def = self:_create_future()
	request = WUtils.id()

	p = {
		request = request,
		procedure = procedure,
		args = params.args,
		kwargs = params.kwargs,
	}
	-- layer in Call message options
	if opts.options then
		p = Utils.extend( opts.options, p )
	end

	msg = WMessageFactory.Call:new( p )

	self._call_reqs[ request ] = { def, opts }

	self._transport:send( msg )

	return def
end


-- Implements :func:`autobahn.wamp.interfaces.ICallee.register`
--
function Session:register( endpoint, params )
	-- print( "Session:register", endpoint )
	params = params or {}
	params.options = params.options or {}
	--==--

	if not self._transport then
		error( WError.TransportLostError() )
	end

	local function _register( obj, endpoint, procedure, options )
		-- print( "_register" )
		local request, msg

		request = WUtils.id()

		self._register_reqs[ request ] = { obj, endpoint, procedure, options }

		msg = WMessageFactory.Register:new{
			request = request,
			procedure = procedure,
			pkeys = options.pkeys,
			disclose_caller = options.disclose_caller,
		}
		self._transport:send( msg )

	end


	if type( endpoint ) == 'function' then
		-- register single callable
		_register( nil, endpoint, params.procedure, params.options )

	elseif type( endpoint ) == 'table' then
		-- register all methods of "wamp_procedure"
		-- TODO
		error( "WAMP:register(): object endpoint not implemented" )
	else
		error( "WAMP:register(): not a proper endpoint type" )
	end

end


function Session:unregister( handler, params )
	-- print( "Session:unregister", handler, params )

	for i, reg in pairs( self._registrations ) do
		local endpoint = reg.endpoint
		if type( handler ) == 'function' and endpoint.fn == handler then
			reg:unsubscribe()
		else
			-- TODO: unregister an object handler
		end
	end

end

-- Called from :meth:`autobahn.wamp.protocol.Registration.unregister`
--
function Session:_unregister( registration )
	-- print( "Session:_unregister", registration )

	assert( registration:isa( Registration ) )
	assert( registration.active )
	assert( self._registrations[ registration.id ] )

	if not self._transport then
		error( WError.TransportLostError() )
	end

	local request, def, msg

	request = WUtils.id()

	def = self._create_future()
	self._unregister_reqs[ request ] = { def, registration }

	msg = WMessageFactory.Unregister:new{
		request=request,
		registration=registration.id
	}

	self._transport:send(msg)

end



--====================================================================--
--== Protocol Facade
--====================================================================--


return {
	Session=Session
}


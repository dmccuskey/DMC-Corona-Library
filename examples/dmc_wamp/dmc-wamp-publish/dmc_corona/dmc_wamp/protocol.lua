--====================================================================--
-- dmc_wamp.protocol
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

local Objects = require 'lua_objects'
local Patch = require('lua_patch')('table-pop')
local Utils = require 'lua_utils'

local MessageFactory = require 'dmc_wamp.messages'
local Role = require 'dmc_wamp.roles'
local FutureMixin = require 'dmc_wamp.future_mix'

local wamp_utils = require 'dmc_wamp.utils'
local wtypes = require 'dmc_wamp.types'

local Errors = require 'dmc_wamp.exception'
local ProtocolError = Errors.ProtocolErrorFactory


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase

local tpop = table.pop



--====================================================================--
-- Endpoint Class
--====================================================================--


local Endpoint = inheritsFrom( ObjectBase )

function Endpoint:_init( params )
	self:superCall( "_init", params )
	--==--
	self.obj = params.obj
	self.fn = params.fn
	self.procedure = params.procedure
	self.options = params.options
end



--====================================================================--
-- Handler Class
--====================================================================--

local Handler = inheritsFrom( ObjectBase )

function Handler:_init( params )
	self:superCall( "_init", params )
	--==--
	self.obj = params.obj
	self.fn = params.fn
	self.topic = params.topic
	self.details_arg = params.details_arg
end



--====================================================================--
-- Publication Class
--====================================================================--

local Publication = inheritsFrom( ObjectBase )

function Publication:_init( params )
	self:superCall( "_init", params )
	--==--
	self.id = params.publication_id
end


--====================================================================--
-- Subscription Class
--====================================================================--

local Subscription = inheritsFrom( ObjectBase )

function Subscription:_init( params )
	self:superCall( "_init", params )
	--==--
	self.session = params.session
	self.id = params.id
	self.active = true

	self.handler = params.handler
end

function Subscription:unsubscribe()
	-- print( "Subscription:unsubscribe" )
	return self.session:_unsubscribe( self )
end



--====================================================================--
-- Registration Class
--====================================================================--

local Registration = inheritsFrom( ObjectBase )

function Registration:_init( params )
	self:superCall( "_init", params )
	--==--
	self.session = params.session
	self.id = params.registration_id
	self.active = true

	self.endpoint = params.endpoint
end

function Registration:unsubscribe()
	-- print( "Registration:unsubscribe" )
	return self.session:_unregister( self )
end



--====================================================================--
-- Base Session Class
--====================================================================--

local BaseSession = inheritsFrom( ObjectBase )

function BaseSession:_init( params )
	self:superCall( "_init", params )
	--==--
	self.debug = params.debug
	self._ecls_to_uri_pat = {}
	self._uri_to_ecls = {}
end

-- Implements :func:`autobahn.wamp.interfaces.ISession.onConnect`
--
function BaseSession:onConnect()
	-- print( "BaseSession:onConnect" )
	--==--
end

-- Implements :func:`autobahn.wamp.interfaces.ISession.onJoin`
--
function BaseSession:onJoin()
	-- print( "BaseSession:onJoin" )
	--==--
end

-- Implements :func:`autobahn.wamp.interfaces.ISession.onLeave`
--
function BaseSession:onLeave()
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
function BaseSession:define()
	-- print( "BaseSession:define" )
	--==--
end

-- Create a WAMP error message from an exception
--
function BaseSession:_message_from_exception()
	-- print( "BaseSession:_message_from_exception" )
	--==--
end

-- Create a user (or generic) exception from a WAMP error message
--
function BaseSession:_exception_from_message()
	-- print( "BaseSession:_exception_from_message" )
	--==--
end



--====================================================================--
-- Application Session Class
--====================================================================--

--[[
Implements
* ISubscriber
* ICaller
--]]

local Session = inheritsFrom( BaseSession )
Session.NAME = "WAMP Session"

Session.EVENT = "wamp_session_event"
Session.ONJOIN = "on_join_wamp_event"

FutureMixin.mixin( Session )


--====================================================================--
--== Start: Setup DMC Objects

function Session:_init( params )
	-- print( "Session:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Create Properties ==--

	self._transport = nil
	self._session_id = nil
	self._realm = params.realm or 'anonymous'

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

--== END: Setup DMC Objects
--====================================================================--



--====================================================================--
--== Public Methods

-- Implements :func:`autobahn.wamp.interfaces.ITransportHandler.onOpen`
--
function Session:onOpen( params )
	-- print( "Session:onOpen" )
	params = params or {}
	--==--
	self._transport = params.transport
	self:onConnect()
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onConnect`
--
function Session:onConnect()
	-- print( "Session:onConnect" )
	self:join()
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.join`
--
function Session:join( realm )
	-- print( "Session:join", realm )

	if self._session_id then error( "Session:join :: already joined" ) end

	local roles, msg

	self._goodbye_sent = false

	roles = {
		Role.callerFeatures,
		Role.subscriberFeatures,
	}

	msg = MessageFactory.Hello:new{
		realm=self._realm,
		roles=roles
	}
	self._transport:send( msg )
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.disconnect`
--
function Session:disconnect()
	-- print( "Session:disconnect" )
	if self._transport then
		self._transport:close()
	else
		-- transport not available
		error("Session:disconnect :: transport not available")
	end
end


-- Implements :func:`autobahn.wamp.interfaces.ITransportHandler.onMessage`
--
function Session:onMessage( msg )
	-- print( "Session:onMessage" )

	if self._session_id == nil then

		-- the first message MUST be Welcome
		if msg:isa( MessageFactory.Welcome ) then
			self._session_id = msg.session

			-- TODO: create session details
			self:onJoin()

		else
			error( ProtocolError( "Received %s message, and session is not yet established" % msg.NAME ) )
		end

		return
	end


	--== Goodbye Message

	if msg:isa( MessageFactory.Goodbye ) then

		if not self._goodbye_sent then
			local reply = MessageFactory.Goodbye:new()
			self._transport:send( reply )
		end

		self._session_id = nil
		self:onLeave( wtypes.CloseDetails( { reason=msg.reason, message=msg.message  } ))


	--== Event Message

	elseif msg:isa( MessageFactory.Event ) then

		if not self._subscriptions[ msg.subscription ] then
			error( ProtocolError( "EVENT received for non-subscribed subscription ID {" ) )
		end

		local sub = self._subscriptions[ msg.subscription ]
		local p, handler

		-- TODO: event details

		p = {
			args=msg.args,
			kwargs=msg.kwargs
		}
		handler = sub.handler
		if handler.fn then handler.fn( p ) end


	--== Published Message

	elseif msg:isa( MessageFactory.Published ) then

		if not self._publish_reqs[ msg.request ] then
			error( ProtocolError( "PUBLISHED received for non-pending request ID" ) )
		end

		local pub_req = tpop( self._publish_reqs, msg.request )
		local def, opts = unpack( pub_req )

		self:_resolve_future( def, Publication:new({ publication_id=msg.publication }) )


	--== Subscribed Message

	elseif msg:isa( MessageFactory.Subscribed ) then
		-- print("onMessage:Subscribed")

		if not self._subscribe_reqs[ msg.request ] then
			error( ProtocolError( "SUBSCRIBED received for non-pending request ID" ) )
		end

		local sub_req = tpop( self._subscribe_reqs, msg.request )
		local func, topic = unpack( sub_req )

		local handler = Handler:new{
			fn=func,
			topic=topic,
			details_arg=nil
		}

		self._subscriptions[ msg.subscription ] = Subscription:new{
			session=self,
			id=msg.subscription,
			handler=handler
		}

		-- TODO: send subscribed notice
		-- p = {
		-- 	args=msg.args,
		-- 	kwargs=msg.kwargs
		-- }
		-- if sub_req.eventHandler then sub_req.eventHandler( p ) end


	--== Unsubscribed Message

	elseif msg:isa( MessageFactory.Unsubscribed ) then


	--== Result Message

	elseif msg:isa( MessageFactory.Result ) then

		if not self._call_reqs[ msg.request ] then
			error( ProtocolError( "RESULT received for non-pending request ID" ) )
		end

		local call_req

		-- TODO: progressive result, etc

		if msg.progress then
			-- Progressive result
			call_req = self._call_reqs[ msg.request ]

		else
			-- Final result
			call_req = tpop( self._call_reqs, msg.request )

			if #msg.args == 1 and not msg.kwargs then
				p = { data=msg.args[1] }
			else
				p = {
					results=msg.args,
					kwresults=msg.kwargs
				}
			end
			if call_req.onResult then call_req.onResult( p ) end
		end


	--== Invocation Message

	elseif msg:isa( MessageFactory.Invocation ) then

		if self._invocations[ msg.request ] then
			error( ProtocolError( "Invocation: already received request for this id" ) )
		end

		if not self._registrations[ msg.registration ] then
			error( ProtocolError( "Invocation: don't have this registration ID" ) )
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

			local reply = MessageFactory.Yield:new{
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

	elseif msg:isa( MessageFactory.Interrupt ) then
		error( "not implemented" )


	--== Registered Message

	elseif msg:isa( MessageFactory.Registered ) then

		if not self._register_reqs[ msg.request ] then
			error( ProtocolError( "REGISTERED received for non-pending request ID" ) )
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

	elseif msg:isa( MessageFactory.Unregistered ) then

		if not self._unregister_reqs[ msg.request ] then
			error( ProtocolError( "UNREGISTERED received for non-pending request ID" ) )
		end

		local unreg_req = tpop( self._unregister_reqs, msg.request )
		local def, registration = unpack( unreg_req )

		self._registrations[ registration.id ] = nil
		registration.active = false
		self:_resolve_future( def, nil )


	--== Unregistered Message

	elseif msg:isa( MessageFactory.Error ) then


	--== Unregistered Message

	elseif msg:isa( MessageFactory.Heartbeat ) then


	else
		if onError then onError( "unknown message class", msg:class().NAME ) end

	end

end


function Session:onClose( msg, onError )
	-- print( "Session:onClose" )

	self._transport = nil

	if self._session_id then
		self:onLeave()
		self._session_id = nil
	end

	self:onDisconnect()

end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onJoin`
--
function Session:onJoin()
	-- print( "Session:onJoin" )
	self:dispatchEvent( self.ONJOIN )
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.onLeave`
--
function Session:onLeave( details )
	-- print( "Session:onLeave" )
	self:disconnect()
end


-- Implements :func:`autobahn.wamp.interfaces.ISession.leave`
--
function Session:leave( params )
	-- print( "Session:leave" )
	params = params or {}
	params.reason = params.reason or 'wamp.close.normal'
	--==--

	if not self._session_id then
		error("no joined"); return
	end

	if self._goodbye_sent then
			error( "Already requested to close the session" )

	else
		local msg = MessageFactory.Goodbye:new( params )
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
		error( TransportError() )
	end

	local options = params.options or {}
	local request = wamp_utils.id()
	local msg = MessageFactory.Publish:new{
		request=request,
		topic=topic,
		options=options,
		args=params.args,
		kwargs=params.kwargs
	}

	if options.acknowledge == true then
		local def = self:_create_future()
		if params.onSuccess or params.onError then
			def:addCallbacks( params.onSuccess, params.onError )
		end
		self._publish_reqs[ request ] = { def, options }
		self._transport:send( msg )
	else
		self._transport:send( msg )
		return

	end
end


-- Implements :func:`autobahn.wamp.interfaces.ISubscriber.subscribe`
--
function Session:subscribe( topic, callback )
	-- print( "Session:subscribe", topic )

	assert( topic )

	if not self._transport then
		error( TransportLostError() )
	end

	-- TODO: register on object
	-- TODO: change onEvent, onSubscribe ? add params to array

	local request, msg

	request = wamp_utils.id()
	self._subscribe_reqs[ request ] = { callback, topic }

	msg = MessageFactory.Subscribe:new{
		request = request,
		topic = topic,
	}
	self._transport:send( msg )

end


function Session:unsubscribe( topic, callback )
	-- print( "Session:unsubscribe", topic, callback )

	for i, sub in pairs( self._subscriptions ) do
		local handler = sub.handler
		if handler.topic == topic and handler.fn == callback then
			sub:unsubscribe()
			break
		end
	end

end


-- Called from :meth:`autobahn.wamp.protocol.Subscription.unsubscribe`
--
function Session:_unsubscribe( subscription )
	-- print( "Session:_unsubscribe", subscription )

	if not self._transport then
		error( TransportLostError() )
	end

	local request, msg

	request = wamp_utils.id()
	msg = MessageFactory.Unsubscribe:new{
		request=request,
		subscription_id = subscription.id
	}
	self._transport:send( msg )

end


function Session:call( procedure, params )
	-- print( "Session:call", procedure )
	params = params or {}
	params.args = params.args or {}
	params.kwargs =  params.kwargs or {}
	--==--

	if not self._transport then
		error( TransportLostError() )
	end

	local request, msg

	request = wamp_utils.id()

	self._call_reqs[ request ] = params

	msg = MessageFactory.Call:new{
		request = request,
		procedure = procedure,
		args = params.args,
		kwargs = params.kwargs,
		--
	}
	self._transport:send( msg )

end


-- Implements :func:`autobahn.wamp.interfaces.ICallee.register`
--
function Session:register( endpoint, params )
	-- print( "Session:register", endpoint )
	params = params or {}
	params.options = params.options or {}
	--==--

	if not self._transport then
		error( TransportLostError() )
	end

	local function _register( obj, endpoint, procedure, options )
		-- print( "_register" )
		local request, msg

		request = wamp_utils.id()

		self._register_reqs[ request ] = { obj, endpoint, procedure, options }

		msg = MessageFactory.Register:new{
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
		error( TransportLostError() )
	end

	local request, def, msg

	request = wamp_utils.id()

	def = self._create_future()
	self._unregister_reqs[ request ] = { def, registration }

	msg = MessageFactory.Unregister:new{
		request=request,
		registration=registration.id
	}

	self._transport:send(msg)

end




--====================================================================--
-- Protocol Facade
--====================================================================--

return {
	Session=Session
}


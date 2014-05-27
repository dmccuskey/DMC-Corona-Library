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

local Objects = require( dmc_lib_func.find('dmc_objects') )
-- local States = require( dmc_lib_func.find('dmc_states') )
local Utils = require( dmc_lib_func.find('dmc_utils') )
local WebSocket = require( dmc_lib_func.find('dmc_websockets') )

local MessageFactory = require( dmc_lib_func.find('dmc_wamp.messages') )
local Role = require( dmc_lib_func.find('dmc_wamp.roles') )

local wamp_utils = require( dmc_lib_func.find('dmc_wamp.utils') )
local wtypes = require( dmc_lib_func.find('dmc_wamp.types') )


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase

-- local control of development functionality
local LOCAL_DEBUG = false



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
Session.NAME = "WAMP Session Class"

Session.EVENT = "wamp_session_event"
Session.ONJOIN = "on_join_wamp_event"

function Session:_init( params )
	-- print( "Session:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Sanity Check ==--

	-- if not self.is_intermediate and ( not params.uri ) then
	-- 	error( "Session: requires parameter 'uri'" )
	-- end

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

	--== Object References ==--

end


function Session:_initComplete()
	-- print( "Session:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

end


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

	if self._session_id then error( "Session:join : already joined" ) end

	local roles, p, msg

	self._goodbye_sent = false

	roles = {
		Role.callerFeatures,
		Role.subscriberFeatures,
	}

	p = {
		realm=self._realm,
		roles=roles
	}
	msg = MessageFactory.create( MessageFactory.Hello.TYPE, p )

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
		print("transport not available")
	end
end


-- Implements :func:`autobahn.wamp.interfaces.ITransportHandler.onMessage`
--
function Session:onMessage( msg, onError )
	-- print( "Session:onMessage" )

	if self._session_id == nil then

		-- the first message MUST be Welcome
		if msg:isa( MessageFactory.Welcome ) then
			self._session_id = msg.session

			self:onJoin()

		else
			-- handle error
			error( "received message, no session" )
		end

		return
	end


	--== Goodbye Message

	if msg:isa( MessageFactory.Goodbye ) then

		if not self._goodbye_sent then
			local msg = MessageFactory.create( MessageFactory.Goodbye.TYPE )
			self._transport:send( msg )
		end

		self._session_id = nil
		self:onLeave( wtypes.CloseDetails( { reason=msg.reason, message=msg.message  } ))


	--== Event Message

	elseif msg:isa( MessageFactory.Event ) then

		local sub = self._subscriptions[ msg.subscription ]
		local p, handler

		if not sub then
			error( "event received for non-subscribed subscription" ); return
		end

		p = {
			args=msg.args,
			kwargs=msg.kwargs
		}
		handler = sub.handler
		if handler.fn then handler.fn( p ) end


	--== Published Message

	elseif msg:isa( MessageFactory.Published ) then
		error( "not implemented" )


	--== Subscribed Message

	elseif msg:isa( MessageFactory.Subscribed ) then
		-- print("onMessage:Subscribed")

		local sub_req = table.pop( self._subscribe_reqs, msg.request )
		local func, topic
		local p, handler

		if not sub_req then
			error( "SUBSCRIBED received for non-pending request ID" ); return
		end

		func, topic = unpack( sub_req )
		p = {
			fn=func,
			topic=topic,
			details_arg=nil
		}
		handler = Handler:new( p )

		p = {
			session=self,
			id=msg.subscription,
			handler=handler
		}
		self._subscriptions[ msg.subscription ] = Subscription:new( p )

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

		local call_req, p
		call_req = self._call_reqs[ msg.request ]

		if not call_req then
			error( "RESULT received for non-pending request ID" )
		end

		if msg.progress then
			-- Progressive result

		else
			-- Final result
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

	elseif msg:isa( MessageFactory.Invocation ) then
		error( "not implemented" )


	--== Interrupt Message

	elseif msg:isa( MessageFactory.Interrupt ) then
		error( "not implemented" )


	--== Registered Message

	elseif msg:isa( MessageFactory.Registered ) then
		error( "not implemented" )


	--== Unregistered Message

	elseif msg:isa( MessageFactory.Unregistered ) then
		error( "not implemented" )


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
		local msg = MessageFactory.create( MessageFactory.Goodbye.TYPE, p )
		self._transport:send( msg )
		self._goodbye_sent = true

	end
end


-- Implements :func:`autobahn.wamp.interfaces.IPublisher.publish`
--
function Session:publish( topic, params )
	-- print( "Session:publish" )
	error( "Session:publish:: not implemented")
end


-- Implements :func:`autobahn.wamp.interfaces.ISubscriber.subscribe`
--
function Session:subscribe( topic, callback )
	-- print( "Session:subscribe", topic )

	if not self._transport then
		callback( "transport lost" ); return
	end

	local request, p, msg

	request = wamp_utils.id()
	self._subscribe_reqs[ request ] = { callback, topic }

	p = {
		request = request,
		topic = topic,
	}
	msg = MessageFactory.create( MessageFactory.Subscribe.TYPE, p )
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
		params.eventHandler( "transport lost" ); return
	end

	local request, p, msg

	request = wamp_utils.id()
	p = {
		request=request,
		subscription_id = subscription.id
	}
	msg = MessageFactory.create( MessageFactory.Unsubscribe.TYPE, p )
	self._transport:send( msg )

end


function Session:call( procedure, params )
	-- print( "Session:call", procedure )
	params = params or {}
	params.args = params.args or {}
	params.kwargs =  params.kwargs or {}
	--==--

	if not self._transport and params.onError then
		params.onError( "transport lost" ); return
	end

	local request, p, msg

	request = wamp_utils.id()
	self._call_reqs[ request ] = params

	p = {
		request = request,
		procedure = procedure,
		args = params.args,
		kwargs = params.kwargs
	}
	msg = MessageFactory.create( MessageFactory.Call.TYPE, p )
	self._transport:send( msg )

end


-- Implements :func:`autobahn.wamp.interfaces.ICallee.register`
--
function Session:register( endpoint, params )
	error( "Session:register:: not implemented")
end




--====================================================================--
-- Protocol Facade
--====================================================================--


return {
	Session=Session
}


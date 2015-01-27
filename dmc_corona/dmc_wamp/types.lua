--====================================================================--
-- dmc_corona/dmc_wamp/types.lua
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
--== DMC Corona Library : DMC WAMP Types
--====================================================================--


--[[
WAMP support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local Objects = require 'lib.dmc_lua.lua_objects'
local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass



--====================================================================--
--== Component Config Class
--====================================================================--


local ComponentConfig = newClass( nil, {name="Component Configuration"} )

function ComponentConfig:__new__( params )
	-- print( "ComponentConfig:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.realm = params.realm
	self.extra = params.extra

	self.authid = params.authid
	self.authmethods = params.authmethods

	self.onchallenge = params.onchallenge
end



--====================================================================--
--== Router Options Class
--====================================================================--

-- not implemented



--====================================================================--
--== Hello Return Class
--====================================================================--


local HelloReturn = newClass( nil, {name="Hello Return Base"} )



--====================================================================--
--== Accept Class
--====================================================================--


local Accept = newClass( HelloReturn, {name="Accept"} )

function Accept:__new__( params )
	-- print( "Accept:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.authid == nil or type( params.authid ) == 'string' )
	assert( params.authrole == nil or type( params.authrole ) == 'string' )
	assert( params.authmethod == nil or type( params.authmethod ) == 'string' )

	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod
end



--====================================================================--
--== Deny Class
--====================================================================--


local Deny = newClass( HelloReturn, {name="Deny"} )

function Deny:__new__( params )
	-- print( "Deny:__new__" )
	params = params or {}
	params.reason = params.reason or "wamp.error.not_authorized"
	self:superCall( '__new__', params )
	--==--
	assert( type( params.reason ) == 'string' )
	assert( params.message==nil or type( params.message )=='string' )

	self.reason = params.reason
	self.message = params.message
end



--====================================================================--
--== Challenge Class
--====================================================================--


local Challenge = newClass( HelloReturn, {name="Challenge"} )


function Challenge:__new__( params )
	-- print( "Challenge:__new__" )
	params = params or {}
	params.extra = params.extra or {}
	self:superCall( '__new__', params )
	--==--
	self.method = params.method
	self.extra = params.extra
end



--====================================================================--
--== Hello Details Class
--====================================================================--


local HelloDetails = newClass( HelloReturn, {name="Hello Details"} )

function HelloDetails:__new__( params )
	-- print( "HelloDetails:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.roles = params.roles
	self.authmethods = params.authmethods
end



--====================================================================--
--== Session Details Class
--====================================================================--


local SessionDetails = newClass( HelloReturn, {name="Session Details"} )

function SessionDetails:__new__( params )
	-- print( "SessionDetails:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.realm = params.realm
	self.session = params.session -- id
	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod
end



--====================================================================--
--== Close Details Class
--====================================================================--


local CloseDetails = newClass( nil, {name="Close Details"} )

function CloseDetails:__new__( params )
	-- print( "CloseDetails:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.reason = params.reason
	self.message = params.message
end



--====================================================================--
--== Subscribe Options Class
--====================================================================--


--[[
Used to provide options for subscribing in
:func:`autobahn.wamp.interfaces.ISubscriber.subscribe`.
--]]

local SubscribeOptions = newClass( nil, {name="Subscribe Options"} )

function SubscribeOptions:__new__( params )
	-- print( "SubscribeOptions:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.match==nil or ( type( params.match ) == 'string' and Utils.propertyIn( { 'exact', 'prefix', 'wildcard' }, params.match ) ) )
	assert( params.details_arg == nil or type( params.details_arg ) == 'string' )

	self.details_arg = params.details_arg
	self.options = {match=params.match}
end



--====================================================================--
--== Event Details Class
--====================================================================--


--[[
Provides details on an event when calling an event handler
previously registered
--]]

local EventDetails = newClass( nil, {name="Event Details"} )

function EventDetails:__new__( params )
	-- print( "EventDetails:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.publication = params.publication
	self.publisher = params.publisher
end



--====================================================================--
--== Publish Options Class
--====================================================================--


local PublishOptions = newClass( nil, {name="Publish Options"} )

function PublishOptions:__new__( params )
	-- print( "PublishOptions:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.acknowledge==nil or type( params.acknowledge )=='boolean' )
	assert( params.excludeMe==nil or type( params.excludeMe )=='boolean' )
	-- TODO: make sure all numbers
	assert( params.exclude==nil or ( type( params.exclude )=='table' ) )
	assert( params.eligible==nil or ( type( params.eligible )=='table' ) )
	assert( params.discloseMe == nil or type( params.discloseMe )=='string' )

	self.options = {
		acknowledge=params.acknowledge,
		excludeMe=params.excludeMe,
		exclude=params.exclude,
		eligible=params.eligible,
		discloseMe=params.discloseMe
	}
end



--====================================================================--
--== Register Options Class
--====================================================================--


local RegisterOptions = newClass( nil, {name="Register Options"} )

function RegisterOptions:__new__( params )
	-- print( "RegisterOptions:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.details_arg = params.details_arg
	self.options = {
		pkeys=params.pkeys,
		disclose_caller=params.disclose_caller
	}
end



--====================================================================--
--== Call Details Class
--====================================================================--


local CallDetails = newClass( nil, {name="Call Details"} )

function CallDetails:__new__( params )
	-- print( "CallDetails:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.progress = params.progress
	self.caller = params.caller
	self.authid = params.authid
	self.authrole = params.authrole
	self.authrole = params.authrole
end



--====================================================================--
--== Call Options Class
--====================================================================--


local CallOptions = newClass( nil, {name="Call Options"} )

function CallOptions:__new__( params )
	-- print( "CallOptions:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	assert( params.onProgress==nil or type( params.onProgress )=='function' )
	assert( params.timeout==nil or ( type( params.timeout )=='number' and params.timeout>0 ) )
	assert( params.discloseMe==nil or type( params.discloseMe )=='boolean' )
	assert( params.runOn==nil or ( type( params.runOn )=='string' and Utils.propertyIn({'all', 'any', 'partition'}, params.runOn)) )

	self.options = {
		timeout=params.timeout,
		discloseMe=params.discloseMe
	}
	self.onProgress = params.onProgress
	if params.onProgress then
		self.options.receive_progress = true
	end

end



--====================================================================--
--== Call Results Class
--====================================================================--


local CallResult = newClass( nil, {name="Call Result"} )

function CallResult:__new__( params )
	-- print( "CallResult:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.results = params.results
	self.kwresults = params.kwresults
end

-- function CallResult:__tostring__()
-- 	return "Call Result"
-- end



--====================================================================--
--== Types Facade
--====================================================================--


return {
	ComponentConfig=ComponentConfig,
	-- Router Options -- not implemented,
	Accept=Accept,
	Deny=Deny,
	Challenge=Challenge,
	HelloDetails=HelloDetails,
	SessionDetails=SessionDetails,
	CloseDetails=CloseDetails,
	SubscribeOptions=SubscribeOptions,
	EventDetails=EventDetails,
	PublishOptions=PublishOptions,
	RegisterOptions=RegisterOptions,
	CallDetails=CallDetails,
	CallOptions=CallOptions,
	CallResult=CallResult
}

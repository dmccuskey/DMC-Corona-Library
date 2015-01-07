--====================================================================--
-- dmc_wamp.types
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

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local Objects = require 'lua_objects'
local Utils = require 'lua_utils'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase



--====================================================================--
--== Component Config Class
--====================================================================--


local ComponentConfig = inheritsFrom( ObjectBase )
ComponentConfig.NAME = "Component Configuration"

function ComponentConfig:_init( params )
	-- print( "ComponentConfig:_init" )
	params = params or {}
	self:superCall( '_init', params )
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


local HelloReturn = inheritsFrom( ObjectBase )
HelloReturn.NAME = "Hello Return Base"



--====================================================================--
--== Accept Class
--====================================================================--


local Accept = inheritsFrom( ObjectBase )
Accept.NAME = "Accept"

function Accept:_init( params )
	-- print( "Accept:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	assert( params.authid == nil or type( params.authid ) == 'string' )
	assert( params.authrole == nil or type( params.authrole ) == 'string' )
	assert( params.authmethod == nil or type( params.authmethod ) == 'string' )
	assert( params.authprovider == nil or type( params.authprovider ) == 'string' )

	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod
	self.authprovider = params.authprovider
end



--====================================================================--
--== Deny Class
--====================================================================--


local Deny = inheritsFrom( HelloReturn )
Deny.NAME = "Deny"

function Deny:_init( params )
	-- print( "Deny:_init" )
	params = params or {}
	params.reason = params.reason or "wamp.error.not_authorized"
	self:superCall( '_init', params )
	--==--
	assert( type( params.reason ) == 'string' )
	assert( params.message == nil or type( params.message ) == 'string' )

	self.reason = params.reason
	self.message = params.message
end



--====================================================================--
--== Challenge Class
--====================================================================--


local Challenge = inheritsFrom( HelloReturn )
Challenge.NAME = "Challenge"


function Challenge:_init( params )
	-- print( "Challenge:_init" )
	params = params or {}
	params.extra = params.extra or {}
	self:superCall( '_init', params )
	--==--
	self.method = params.method
	self.extra = params.extra
end



--====================================================================--
--== Hello Details Class
--====================================================================--


local HelloDetails = inheritsFrom( HelloReturn )
HelloDetails.NAME = "Hello Details"

function HelloDetails:_init( params )
	-- print( "HelloDetails:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.roles = params.roles
	self.authmethods = params.authmethods
	self.authid = params.authid
	self.pending_session = params.pending_session
end



--====================================================================--
--== Session Details Class
--====================================================================--


local SessionDetails = inheritsFrom( HelloReturn )
SessionDetails.NAME = "Session Details Class"

function SessionDetails:_init( params )
	-- print( "SessionDetails:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.realm = params.realm
	self.session = params.session -- id
	self.authid = params.authid
	self.authrole = params.authrole
	self.authmethod = params.authmethod
	self.authprovider = params.authprovider
end



--====================================================================--
--== Close Details Class
--====================================================================--


local CloseDetails = inheritsFrom( ObjectBase )
CloseDetails.NAME = "Close Details"

function CloseDetails:_init( params )
	-- print( "CloseDetails:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.reason = params.reason
	self.message = params.message
end



--====================================================================--
--== Subscribe Options Class
--====================================================================--


local SubscribeOptions = inheritsFrom( ObjectBase )
SubscribeOptions.NAME = "Subscribe Options"

function SubscribeOptions:_init( params )
	-- print( "SubscribeOptions:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	assert( params.match==nil or ( type( params.match ) == 'string' and Utils.propertyIn( { 'exact', 'prefix', 'wildcard' }, params.match ) ) )
	assert( params.details_arg == nil or type( params.details_arg ) == 'string' )

	self.match = params.match
	self.details_arg = params.details_arg

	-- options dict as sent within WAMP message
	self.options = {match=match}
end



--====================================================================--
--== Register Options Class
--====================================================================--


local RegisterOptions = inheritsFrom( ObjectBase )
RegisterOptions.NAME = "Register Options"

function RegisterOptions:_init( params )
	-- print( "RegisterOptions:_init" )
	params = params or {}
	self:superCall( '_init', params )
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


local CallDetails = inheritsFrom( ObjectBase )
CallDetails.NAME = "Call Details"

function CallDetails:_init( params )
	-- print( "CallDetails:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.progress = params.progress
	self.caller = params.caller
	self.authid = params.authid
	self.authrole = params.authrole
	self.authrole = params.authrole
end




--====================================================================--
--== Types Facade
--====================================================================--

return {
	ComponentConfig=ComponentConfig,
	-- Router Options,
	Accept=Accept,
	Deny=Deny,
	Challenge=Challenge,
	HelloDetails=HelloDetails,
	SessionDetails=SessionDetails,
	SubscribeOptions=SubscribeOptions,
	RegisterOptions=RegisterOptions,
	CallDetails=CallDetails,
	CloseDetails=CloseDetails,
}

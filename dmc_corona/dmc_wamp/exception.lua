--====================================================================--
-- dmc_wamp/exception.lua
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
--== DMC Corona Library : DMC WAMP Exception
--====================================================================--


--[[
WAMP support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local Error = require 'lib.dmc_lua.lua_error'
local Objects = require 'lib.dmc_lua.lua_objects'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass



--====================================================================--
--== WAMP Base Error Class
--====================================================================--


--[[
Base class for all exceptions related to WAMP
--]]

local WAMPError = newClass( Error, {name="WAMP Error Base"} )

function WAMPError:__new__( reason )
	-- print( "WAMPError:__new__" )
	local p = {
		reason or "unknown reason"
	}
	self:superCall( '__new__', p )
	--==--
	self.reason = p.reason
end



--====================================================================--
--== Session Not Ready Error Class
--====================================================================--


--[[
The application tried to perform a WAMP interaction, but the
session is not yet fully established
--]]

local SessionNotReady = newClass( WAMPError, {name="Session Not Ready Error"} )



--====================================================================--
--== Protocol Error Class
--====================================================================--


--[[
Exception raised when WAMP protocol was violated. Protocol errors
are fatal and are handled by the WAMP implementation. They are
not supposed to be handled at the application level
--]]

local ProtocolError = newClass( WAMPError, {name="Protocol Error"} )



--====================================================================--
--== Transport Lost Error Class
--====================================================================--


--[[
Exception raised when the transport underlying
the WAMP session was lost or is not connected
--]]

local TransportLost = newClass( WAMPError, {name="Transport Lost Error"} )


function TransportLost:__new__( reason )
	-- print( "TransportLost:__new__" )
	local p = {
		reason="WAMP transport lost"
	}
	self:superCall( '__new__', p )
end




--====================================================================--
--== Application Error Class
--====================================================================--


--[[
Exception raised when the transport underlying
the WAMP session was lost or is not connected
--]]

local ApplicationError = newClass( WAMPError, {name="Application Error"} )

--[[
Peer provided an incorrect URI for a URI-based attribute
of a WAMP message such as a realm, topic or procedure.
--]]
ApplicationError.INVALID_URL = "wamp.error.invalid_uri"

--[[
A Dealer could not perform a call, since not procedure is currently registered
under the given URI.
--]]
ApplicationError.NO_SUCH_PROCEDURE = "wamp.error.no_such_procedure"

--[[
A procedure could not be registered, since a procedure with the given URI is
already registered.
--]]
ApplicationError.PROCEDURE_ALREADY_EXISTS = "wamp.error.procedure_already_exists"

--[[
A Dealer could not perform a unregister, since the given registration is not active.
--]]
ApplicationError.NO_SUCH_REGISTRATION = "wamp.error.no_such_registration"

--[[
A Broker could not perform a unsubscribe, since the given subscription is not active.
--]]
ApplicationError.NO_SUCH_SUBSCRIPTION = "wamp.error.no_such_subscription"

--[[
A call failed, since the given argument types or values are not acceptable to the
called procedure - in which case the *Callee* may throw this error. Or a Router
performing *payload validation* checked the payload (``args`` / ``kwargs``) of a call,
call result, call error or publish, and the payload did not conform.
--]]
ApplicationError.INVALID_ARGUMENT = "wamp.error.invalid_argument"

-- FIXME: this currently isn't used neither in Autobahn nor Crossbar. Check!
--[[
The *Peer* is shutting down completely - used as a ``GOODBYE`` (or ``ABORT``) reason.
--]]
ApplicationError.SYSTEM_SHUTDOWN = "wamp.error.system_shutdown"

-- FIXME: this currently isn't used neither in Autobahn nor Crossbar. Check!
--[[
The *Peer* want to leave the realm - used as a ``GOODBYE`` reason.
--]]
ApplicationError.CLOSE_REALM = "wamp.error.close_realm"

-- FIXME: this currently isn't used neither in Autobahn nor Crossbar. Check!
--[[
A *Peer* acknowledges ending of a session - used as a ``GOOBYE`` reply reason.
--]]
ApplicationError.GOODBYE_AND_OUT = "wamp.error.goodbye_and_out"

--[[
A call, register, publish or subscribe failed, since the session is not authorized
to perform the operation.
--]]
ApplicationError.NOT_AUTHORIZED = "wamp.error.not_authorized"

--[[
A Dealer or Broker could not determine if the *Peer* is authorized to perform
a join, call, register, publish or subscribe, since the authorization operation
*itself* failed. E.g. a custom authorizer did run into an error.
--]]
ApplicationError.AUTHORIZATION_FAILED = "wamp.error.authorization_failed"

--[[
Peer wanted to join a non-existing realm (and the *Router* did not allow to auto-create
the realm).
--]]
ApplicationError.NO_SUCH_REALM = "wamp.error.no_such_realm"

--[[
A *Peer* was to be authenticated under a Role that does not (or no longer) exists on the Router.
For example, the *Peer* was successfully authenticated, but the Role configured does not
exists - hence there is some misconfiguration in the Router.
--]]
ApplicationError.NO_SUCH_ROLE = "wamp.error.no_such_role"

-- FIXME: this currently isn't used neither in Autobahn nor Crossbar. Check!
--[[
A Dealer or Callee canceled a call previously issued (WAMP AP).
--]]
ApplicationError.CANCELED = "wamp.error.canceled"

-- FIXME: this currently isn't used neither in Autobahn nor Crossbar. Check!
--[[
A Router rejected client request to disclose its identity (WAMP AP).
--]]
ApplicationError.OPTION_DISALLOWED_DISCLOSE_ME = "wamp.error.option_disallowed.disclose_me"

-- FIXME: this currently isn't used neither in Autobahn nor Crossbar. Check!
--[[
A *Dealer* could not perform a call, since a procedure with the given URI is registered,
but *Callee Black- and Whitelisting* and/or *Caller Exclusion* lead to the
exclusion of (any) *Callee* providing the procedure (WAMP AP).
--]]
ApplicationError.NO_ELIGIBLE_CALLEE = "wamp.error.no_eligible_callee"


-- TODO: integrate with Exception Class
--
-- params.error - The URI of the error that occurred, eg `wamp.error.not_authorized`
--
function ApplicationError:__new__( params )
	-- print( "ApplicationError:__new__" )
	params = params or {}
	self:superCall( '__new__', p )
	--==--
	assert( type( params.error ) == 'string' )

	self.error = params.error
	self.params = params
end






--====================================================================--
--== Exception Facade
--====================================================================--


local function ProtocolErrorFactory( reason )
	-- print( "ProtocolErrorFactory", reason )
	return ProtocolError{ reason=reason }
end


return {
	SessionNotReady=SessionNotReady,
	ProtocolError=ProtocolError,
	ProtocolErrorFactory=ProtocolErrorFactory,
	TransportLost=TransportLost,
	ApplicationError=ApplicationError
}

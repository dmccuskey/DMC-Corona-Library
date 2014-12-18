--====================================================================--
-- dmc_wamp.roles
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

local Errors = require 'dmc_wamp.exception'
local ProtocolError = Errors.ProtocolErrorFactory



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase



--====================================================================--
--== Role Features
--====================================================================--


local RoleFeatures = inheritsFrom( ObjectBase )
RoleFeatures.NAME = "Role Features Base"

RoleFeatures.ROLE = nil

function RoleFeatures:_filterAttributes()
	-- print( "RoleFeatures:_filterAttributes" )
	local attrs = {}

	for k,v in pairs( self ) do
		if k:sub(1,1) ~= '_' and not Utils.propertyIn( { 'is_intermediate' }, k ) then
			-- print(k,v)
			local attr = rawget( self, k )
			if attr ~= nil then
				attrs[k]=v
			end
		end
	end

	return attrs
end

function RoleFeatures:_check_all_bool()
	-- print( "RoleFeatures:_check_all_bool" )

	local attrs = self:_filterAttributes()
	for k,v in pairs( attrs ) do
		-- print("checking", k, v )
		if type(v) ~= 'boolean' then
			error( ProtocolError( "invalid type '%s' for feature '%s' for role '%s'" % {type(v), k, self.ROLE } ) )
		end
	end

end

function RoleFeatures:getFeatures()
	-- print( "RoleFeatures:getFeatures" )
	local features = {}
	local attrs = self:_filterAttributes()

	-- for k,v in pairs( attrs ) do
	-- 	print(k,v)
	-- end

	return attrs
end



--====================================================================--
--== Common Pub/Sub-Role Features
--====================================================================--


local RoleCommonPubSubFeatures = inheritsFrom( RoleFeatures )
RoleCommonPubSubFeatures.NAME = "Common Pub/Sub Feature"


function RoleCommonPubSubFeatures:_init( params )
	-- print( "RoleCommonPubSubFeatures:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.publisher_identification = params.publisher_identification
	self.partitioned_pubsub = params.partitioned_pubsub
end



--====================================================================--
--== Broker-Role Features
--====================================================================--

-- not implemented



--====================================================================--
--== Subscriber-Role Features
--====================================================================--



local RoleSubscriberFeatures = inheritsFrom( RoleCommonPubSubFeatures )
RoleSubscriberFeatures.NAME = "Subscriber-Role Feature"

RoleSubscriberFeatures.ROLE = 'subscriber'


function RoleSubscriberFeatures:_init( params )
	-- print( "RoleSubscriberFeatures:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.publication_trustlevels = params.publication_trustlevels
	self.pattern_based_subscription = params.pattern_based_subscription
	self.subscriber_metaevents = params.subscriber_metaevents
	self.subscriber_list = params.subscriber_list
	self.event_history = params.event_history
end

function RoleSubscriberFeatures:_initComplete()
	-- print( "RoleSubscriberFeatures:_initComplete" )
	--==--
	self:_check_all_bool()
end



--====================================================================--
--== Publisher-Role Features
--====================================================================--


local RolePublisherFeatures = inheritsFrom( RoleCommonPubSubFeatures )
RolePublisherFeatures.NAME = "Publisher-Role Feature"

RolePublisherFeatures.ROLE = 'publisher'


function RolePublisherFeatures:_init( params )
	-- print( "RolePublisherFeatures:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.subscriber_blackwhite_listing = params.subscriber_blackwhite_listing
	self.publisher_exclusion = params.publisher_exclusion
end

function RolePublisherFeatures:_initComplete()
	-- print( "RolePublisherFeatures:_initComplete" )
	--==--
	self:_check_all_bool()
end



--====================================================================--
--== Common RPC-Role Features
--====================================================================--


local RoleCommonRpcFeatures = inheritsFrom( RoleFeatures )
RoleCommonRpcFeatures.NAME = "Common RPC-Role Feature"


function RoleCommonRpcFeatures:_init( params )
	-- print( "RoleCommonRpcFeatures:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.caller_identification = params.caller_identification
	self.partitioned_rpc = params.partitioned_rpc
	self.call_timeout = params.call_timeout
	self.call_canceling = params.call_canceling
	self.progressive_call_results = params.progressive_call_results
end



--====================================================================--
--== Dealer-Role Features
--====================================================================--

-- not implemented



--====================================================================--
--== Caller-Role Features
--====================================================================--


local RoleCallerFeatures = inheritsFrom( RoleCommonRpcFeatures )
RoleCallerFeatures.NAME = "Caller-Role Feature"

RoleCallerFeatures.ROLE = 'caller'


function RoleCallerFeatures:_init( params )
	-- print( "RoleCallerFeatures:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.callee_blackwhite_listing = params.callee_blackwhite_listing
	self.caller_exclusion = params.caller_exclusion
end

function RoleCallerFeatures:_initComplete()
	-- print( "RoleCallerFeatures:_initComplete" )
	--==--
	self:_check_all_bool()
end



--====================================================================--
--== Callee-Role Features
--====================================================================--


local RoleCalleeFeatures = inheritsFrom( RoleCommonRpcFeatures )
RoleCalleeFeatures.NAME = "Callee-Role Feature"

RoleCalleeFeatures.ROLE = 'callee'


function RoleCalleeFeatures:_init( params )
	-- print( "RoleCalleeFeatures:_init" )
	params = params or {}
	self:superCall( '_init', params )
	--==--
	self.call_trustlevels = params.call_trustlevels
	self.pattern_based_registration = params.pattern_based_registration
end

function RoleCalleeFeatures:_initComplete()
	-- print( "RoleCalleeFeatures:_initComplete" )
	--==--
	self:_check_all_bool()
end




--====================================================================--
--== Roles Facade
--====================================================================--


return {
	-- broker,
	RoleSubscriberFeatures=RoleSubscriberFeatures,
	RolePublisherFeatures=RolePublisherFeatures,
	-- dealer,
	RoleCallerFeatures=RoleCallerFeatures,
	RoleCalleeFeatures=RoleCalleeFeatures,
}

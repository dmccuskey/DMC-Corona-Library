--====================================================================--
-- dmc_wamp.roles
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_wamp.lua
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
--== DMC Corona Library : DMC WAMP
--====================================================================--


--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local WErrors = require 'dmc_wamp.exception'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass



--====================================================================--
--== Role Features
--====================================================================--


local RoleFeatures = newClass( nil, { name="Role Features Base" } )

RoleFeatures.ROLE = nil

function RoleFeatures:_filterAttributes()
	-- print( "RoleFeatures:_filterAttributes" )
	local attrs = {}

	for k,v in pairs( self ) do
		if k:sub(1,1) ~= '_' and not Utils.propertyIn( { 'is_class' }, k ) then
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
			error( WErrors.ProtocolError( "invalid type '%s' for feature '%s' for role '%s'" % {type(v), k, self.ROLE } ) )
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


local RoleCommonPubSubFeatures = newClass( RoleFeatures, { name="Common Pub/Sub Feature" } )

function RoleCommonPubSubFeatures:__new__( params )
	-- print( "RoleCommonPubSubFeatures:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
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


local RoleSubscriberFeatures = newClass( RoleCommonPubSubFeatures, { name="Subscriber-Role Feature" } )

RoleSubscriberFeatures.ROLE = 'subscriber'

function RoleSubscriberFeatures:__new__( params )
	-- print( "RoleSubscriberFeatures:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.publication_trustlevels = params.publication_trustlevels
	self.pattern_based_subscription = params.pattern_based_subscription
	self.subscriber_metaevents = params.subscriber_metaevents
	self.subscriber_list = params.subscriber_list
	self.event_history = params.event_history

	self:_check_all_bool()
end

-- function RoleSubscriberFeatures:__initComplete__()
-- 	-- print( "RoleSubscriberFeatures:__initComplete__" )
-- 	--==--
-- 	self:_check_all_bool()
-- end



--====================================================================--
--== Publisher-Role Features
--====================================================================--


local RolePublisherFeatures = newClass( RoleCommonPubSubFeatures, { name="Publisher-Role Feature" } )

RolePublisherFeatures.ROLE = 'publisher'

function RolePublisherFeatures:__new__( params )
	-- print( "RolePublisherFeatures:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.subscriber_blackwhite_listing = params.subscriber_blackwhite_listing
	self.publisher_exclusion = params.publisher_exclusion

	self:_check_all_bool()
end

-- function RolePublisherFeatures:__initComplete__()
-- 	-- print( "RolePublisherFeatures:__initComplete__" )
-- 	--==--
-- 	self:_check_all_bool()
-- end



--====================================================================--
--== Common RPC-Role Features
--====================================================================--


local RoleCommonRpcFeatures = newClass( RoleFeatures, { name="Common RPC-Role Feature" } )

function RoleCommonRpcFeatures:__new__( params )
	-- print( "RoleCommonRpcFeatures:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
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


local RoleCallerFeatures = newClass( RoleCommonRpcFeatures, { name="Caller-Role Feature" } )

RoleCallerFeatures.ROLE = 'caller'

function RoleCallerFeatures:__new__( params )
	-- print( "RoleCallerFeatures:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.callee_blackwhite_listing = params.callee_blackwhite_listing
	self.caller_exclusion = params.caller_exclusion

	self:_check_all_bool()
end

-- function RoleCallerFeatures:__initComplete__()
-- 	-- print( "RoleCallerFeatures:__initComplete__" )
-- 	--==--
-- 	self:_check_all_bool()
-- end



--====================================================================--
--== Callee-Role Features
--====================================================================--


local RoleCalleeFeatures = newClass( RoleCommonRpcFeatures, { name="Callee-Role Feature" } )

RoleCalleeFeatures.ROLE = 'callee'

function RoleCalleeFeatures:__new__( params )
	-- print( "RoleCalleeFeatures:__new__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--
	self.call_trustlevels = params.call_trustlevels
	self.pattern_based_registration = params.pattern_based_registration

	self:_check_all_bool()
end

-- function RoleCalleeFeatures:__initComplete__()
-- 	-- print( "RoleCalleeFeatures:__initComplete__" )
-- 	--==--
-- 	self:_check_all_bool()
-- end




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

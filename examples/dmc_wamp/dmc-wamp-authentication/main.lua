--====================================================================--
-- WAMP Basic Publish/Subscribe
--
-- Basic Pub/Sub test for the WAMP library
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


-- read in app deployment configuration, global
_G.gINFO = require 'app_config'

local Wamp = require 'dmc_corona.dmc_wamp'

local crypto = require 'crypto'



--====================================================================--
--== Setup, Constants


-- WAMP server info in file 'app_config.lua'
--
local HOST = gINFO.server.host
local PORT = gINFO.server.port
local REALM = gINFO.server.realm
local WAMP_SUB_TOPIC = gINFO.server.sub_topic

local wamp -- ref to WAMP object



--====================================================================--
--== Support Functions


local doWampPubSub = function()
	print( ">> WAMP:doWampPubSub" )

	local topic = WAMP_SUB_TOPIC

	local subscriptionEvent_handler = function( event )
		print( ">> WAMP PubSub::subscription Event handler" )

		if event.is_error then
			-- could be issue with subscription request
			-- or network close (maybe)
		else
			-- print( event.args, event.kwargs )
			if event.args then
				for i,v in ipairs( event.args ) do
					print( '  args', i, v )
				end
			end
		end
	end

	-- subscribe to topic
	wamp:subscribe( topic, subscriptionEvent_handler )

	-- unsubscribe from topic
	local unsub = function( e )
		wamp:unsubscribe( topic, subscriptionEvent_handler )
	end
	timer.performWithDelay( 5000, unsub )

	-- close connection
	timer.performWithDelay( 8000, function(e) wamp:leave() end  )

end

local mime = require 'mime'
local mbase64_encode = mime.b64

local function compute_wcs( key, challenge )
	print( "compute_wcs ", key, challenge )
	assert( type(key)=='string' )

	local sig = crypto.hmac( crypto.sha256, challenge, key, true )

	sig = mbase64_encode( sig )

	print( sig )

	return sig
end


--====================================================================--
--== Main
--====================================================================--

local function onChallenge( event )
	local session = event.session
	local method = event.method
	local extra = event.extra

	local signature

	if method == 'wampcra' then
		return compute_wcs( gINFO.user.secret, extra.challenge )
	else
		error( "don't know how to handle auth method" )
	end

	return
end


local wampEvent_handler = function( event )
	print( ">> wampEvent_handler", event.type )

	if event.type == wamp.ONCONNECT then
		print( ">> We have WAMP Connect" )
		doWampPubSub()

	elseif event.type == wamp.ONDISCONNECT then
		print( ">> We have WAMP Disconnect" )
	end

end

print( "WAMP: Starting WAMP Communication" )

wamp = Wamp:new{
	uri=HOST,
	port=PORT,
	protocols={ 'wamp.2.json' },
	realm=REALM,
	user_id=gINFO.user.id,
	auth_methods=gINFO.user.authmethods,
	onChallenge=onChallenge
}
wamp:addEventListener( wamp.EVENT, wampEvent_handler )

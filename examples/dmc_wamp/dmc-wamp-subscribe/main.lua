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
-- Imports

local Wamp = require 'dmc_library.dmc_wamp'


--====================================================================--
-- Setup, Constants

--== Fill in the IP Address and Port for the WAMP Server
--
local host, port, realm = 'ws://192.168.0.102', 8080, 'realm1'

local wamp -- ref to WAMP object


--====================================================================--
-- Support Functions

local doWampPubSub = function()
	print( ">> WAMP:doWampPubSub" )

	local topic = 'com.myapp.topic1'

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



--====================================================================--
-- Main
--====================================================================--

local wampEvent_handler = function( event )
	print( ">> wampEvent_handler", event.type )

	if event.type == wamp.ONCONNECT then
		print( ">> We have WAMP Connect" )
		doWampPubSub()

	elseif event.type == wamp.ONDISCONNECT then
		print( ">> We have WAMP Disconnect" )
	end

end

local params = {
	uri=host,
	port=port,
	protocols={ 'wamp.2.json' },
	realm=realm
}
wamp = Wamp:new( params )
wamp:addEventListener( wamp.EVENT, wampEvent_handler )

--====================================================================--
-- WAMP Basic Publish
--
-- Basic Publish test for the WAMP library
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

local Wamp = require 'dmc_corona.dmc_wamp'

-- read in app deployment configuration, global
_G.gINFO = require 'app_config'



--====================================================================--
--== Setup, Constants


--== Fill in the IP Address and Port for the WAMP Server
--
local HOST = gINFO.server.host
local PORT = gINFO.server.port
local REALM = gINFO.server.realm

local wamp -- ref to WAMP object
local doWampPublish -- forward delare function

-- config for message count
local num_msgs = 5
local count = 0



--====================================================================--
--== Support Functions


doWampPublish = function()
	print( ">> Wamp Publish event")

	local topic = 'com.myapp.topic1'

	local publish_handler = function( publication )
		print( ">> WAMP publish acknowledgment" )

		print( string.format( "publish id: %d", publication.id ) )

		if count == num_msgs then
			-- wamp:close()
		else
			timer.performWithDelay( 500, function() doWampPublish() end )
		end
	end

	count = count + 1
	local params = {
		options={ acknowledge=true },
		args={ "hello-" .. tostring(i) },
		kwargs={},
		onSuccess=publish_handler,
		onError=publish_handler
	}
	wamp:publish( topic, params )

end



--====================================================================--
--== Main
--====================================================================--


local wampEvent_handler = function( event )
	print( ">> wampEvent_handler", event.type )

	if event.type == wamp.ONCONNECT then
		print( ">> We have WAMP Connect" )
		doWampPublish()

	elseif event.type == wamp.ONDISCONNECT then
		print( ">> We have WAMP Disconnect" )
	end

end

print( "WAMP: Starting WAMP Communication" )

wamp = Wamp:new{
	uri=HOST,
	port=PORT,
	protocols={ 'wamp.2.json' },
	realm=REALM
}
wamp:addEventListener( wamp.EVENT, wampEvent_handler )

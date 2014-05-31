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
-- Imports

local Wamp = require 'dmc_corona.dmc_wamp'


--====================================================================--
-- Setup, Constants

--== Fill in the IP Address and Port for the WAMP Server
--
local host, port, realm = 'ws://192.168.0.102', 8080, 'realm1'

local wamp -- ref to WAMP object


--====================================================================--
-- Support Functions

local function doWampPublish()
	print( ">> doWampPublish")

	local topic, onAcknowledge_handler

	topic = 'com.myapp.topic1'
	publish_handler = function( publication )
		print( ">> WAMP publish acknowledgment" )

		print( "publish id", publication.id )
	end

	for i=1,10 do
		local params = {
			options={ acknowledge=true },
			args={ "hello-" .. tostring(i) },
			kwargs={},
			onSuccess=publish_handler,
			onError=publish_handler
		}
		wamp:publish( topic, params )
	end

end



--====================================================================--
-- Main
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

local params = {
	uri=host,
	port=port,
	protocols={ 'wamp.2.json' },
	realm=realm
}
wamp = Wamp:new( params )
wamp:addEventListener( wamp.EVENT, wampEvent_handler )

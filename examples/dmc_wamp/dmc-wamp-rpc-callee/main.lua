--====================================================================--
-- WAMP Basic RPC
--
-- Basic RPC for the WAMP library
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
-- local Utils = require 'dmc_corona.dmc_utils'



--====================================================================--
--== Setup, Constants


-- WAMP server info in file 'app_config.lua'
--
local HOST = gINFO.server.host
local PORT = gINFO.server.port
local REALM = gINFO.server.realm
local WAMP_RPC_PROCEDURE = gINFO.server.rpc_procedure

local wamp -- ref to WAMP object



--====================================================================--
--== Support Functions


local registerWampRPC = function()
	print( ">> WAMP:registerWampRPC" )


	local handler = function( args, kwargs )
		print( "in callee handler", args, kwargs )

		-- Utils.print( kwargs )
		-- wamp:yield( 'this is my data!!', args, kwargs )
		-- wamp:error( 'houston, we have a problem!!' )
		print( 'timestamp', ts )
		return { results={ os.time() }, kwresults = nil }

	end

	local params = {
		procedure=WAMP_RPC_PROCEDURE
	}

	if wamp.is_connected then
		local deferred = wamp:register( handler, params )

		timer.performWithDelay( 20000, function() wamp:unregister( handler, params ) end )
	end

end



--====================================================================--
--== Main
--====================================================================--


local wampEvent_handler = function( event )
	print( ">> wampEvent_handler", event.type )

	if event.type == wamp.ONCONNECT then
		print( ">> We have WAMP Connect" )
		registerWampRPC()

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

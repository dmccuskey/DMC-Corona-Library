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


local doWampRPC = function()
	print( ">> WAMP:doWampRPC" )

	local procedure = WAMP_RPC_PROCEDURE

	local params = {
		-- args = {},
		-- kwargs = {},
		-- timeout = 2000,
		onResult=function( e )
			print( ">> WAMP RPC::onResult handler" )
			if e.data then
				print( '>>  data', e.data )
			end
			if e.results then
				for i,v in ipairs( e.results ) do
					print( '>>  results', i, v )
				end
			end
			if e.kwresults then
				for k,v in pairs( e.kwresults ) do
					print( '>>  kwresults', k, v )
				end
			end
		end,
		onProgress=function(e) end,
		onError=function(e) end
	}
	if wamp.is_connected then
		local deferred = wamp:call( procedure, params )
	end

	-- close connection
	timer.performWithDelay( 4000, function(e) wamp:leave() end  )

end



--====================================================================--
--== Main
--====================================================================--


local wampEvent_handler = function( event )
	print( ">> wampEvent_handler", event.type )

	if event.type == wamp.ONCONNECT then
		print( ">> We have WAMP Connect" )
		doWampRPC()

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

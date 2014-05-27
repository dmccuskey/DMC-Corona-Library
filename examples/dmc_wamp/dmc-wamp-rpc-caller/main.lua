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

local doWampRPC = function()
	print( ">> WAMP:doWampRPC" )

	local procedure = 'com.timeservice.now'

	local params = {
		-- args = {},
		-- kwargs = {},
		-- timeout = 2000,
		onResult=function( e )
			print( ">> WAMP RPC::onResult handler" )
			if e.data then
				print( '  data', e.data )
			end
			if e.results then
				for i,v in ipairs( e.results ) do
					print( '  results', i, v )
				end
			end
			if e.kwresults then
				for k,v in pairs( e.kwresults ) do
					print( '  kwresults', k, v )
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
-- Main
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

local params = {
	uri=host,
	port=port,
	protocols={ 'wamp.2.json' },
	realm=realm
}
wamp = Wamp:new( params )
wamp:addEventListener( wamp.EVENT, wampEvent_handler )

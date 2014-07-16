--====================================================================--
-- dmc_websockets: Autobahn Test Suite
--
-- Run through the Autobahn Websocket Test Suite
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--


print( '\n\n##############################################\n\n' )


--====================================================================--
-- Imports

local WebSockets = require 'dmc_corona.dmc_websockets'

local test_cases = require 'test_cases'
local Patch = require( 'lua_patch' )( 'string-format' )

-- read in app deployment configuration
gAPP_CONF = require 'app_config'


--====================================================================--
-- Setup, Constants

local ws
local test_idx = 0
local current_test = nil -- test case record

local deploy_conf = gAPP_CONF.deployment
if deploy_conf.io_buffering_active then
	-- **debug: disable output buffering for Xcode Console
	io.output():setvbuf('no')
end

local LOCAL_DEBUG = false


--====================================================================--
-- Support Functions

local doTest, gotoNextTest
local ws_handler


local function createURI( params )
	assert( params.server_url )
	assert( params.server_port )
	assert( params.test_index )
	assert( params.user_agent )
	--==--
	return 'ws://%s:%s/runCase?case=%s&agent=%s' % {
		params.server_url,
		params.server_port,
		params.test_index,
		params.user_agent
	}
end


ws_handler = function( event )
	-- print( "ws_handler", event.type )
	local evt_type = event.type

	if evt_type == ws.ONOPEN then
		if LOCAL_DEBUG then
			print( 'Received event: ONOPEN' )
		end

	elseif evt_type == ws.ONMESSAGE then
		local msg = event.message
		if LOCAL_DEBUG then
			print( "Received event: ONMESSAGE, len", #msg.data )
		end
		ws:send( msg.data )

	elseif evt_type == ws.ONCLOSE then
		if LOCAL_DEBUG then
			print( 'Received event: ONCLOSE' )
			print( 'code:reason', event.code, event.reason )
		end
		gotoNextTest()

	elseif evt_type == ws.ONERROR then
		if LOCAL_DEBUG then
			print( 'Received event: ONERROR' )
			print( 'code:reason', event.code, event.reason )
		end

	end
end

doTest = function( test_case )
	local out = {
		-- "\n\n=== dmc_websockets: doTest ===\n",
		"Performing Test %s : %s\n" % { test_case.id, test_case.desc }
	}
	print( table.concat( out, '' ) )

	if ws then
		ws:removeEventListener( ws.EVENT, ws_handler )
		ws:removeSelf()
	end

	-- create new socket
	ws = WebSockets{
		uri=createURI{
			server_url=deploy_conf.server_url,
			server_port=deploy_conf.server_port,
			test_index=test_case.index,
			user_agent=WebSockets.USER_AGENT
		},
		-- throttle=WebSockets.OFF,
	}
	ws:addEventListener( ws.EVENT, ws_handler )

end

gotoNextTest = function()
	-- print( "gotoNextTest" )
	test_idx = test_idx + 1
	if test_idx <= #test_cases then
		current_test = test_cases[ test_idx ]
		doTest( current_test )

	else
		print( "\n\ndmc_websockets: Autobahn Testing is complete" )

	end
end


--====================================================================--
-- Main Functions

print( "dmc_websockets: Start Autobahn Testing\n\n" )
gotoNextTest()

--====================================================================--
-- dmc_websockets: Autobahn Test Suite
--
-- Run through the Autobahn Websocket Test Suite
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

local WebSockets = require 'dmc_corona.dmc_websockets'
-- local Utils = require( "dmc_corona.dmc_utils" )

local test_cases = require 'test_cases'
local patch = require 'dmc_patch'


--====================================================================--
-- Setup, Constants

local ws
local test_idx = 0
local current_test = nil -- test case record


--====================================================================--
-- Support Functions

local doTest, gotoNextTest
local ws_handler


ws_handler = function( event )
	print( "ws_handler", event.type )
	local evt_type = event.type

	if evt_type == ws.ONOPEN then
		print( 'Received event: ONOPEN' )

	elseif evt_type == ws.ONMESSAGE then
		local msg = event.message

		print( "Received event: ONMESSAGE, len", #msg.data )
		-- print( "message text: '" .. tostring( msg.data ) .. "'\n\n" )
		ws:send( msg.data )
		-- timer.performWithDelay( 1000, function() ws:close() end )

	elseif evt_type == ws.ONCLOSE then
		print( "Received event: ONCLOSE" )

		gotoNextTest()

	elseif evt_type == ws.ONERROR then
		print( "Received event: ONERROR" )
		-- Utils.print( event )

	end
end

doTest = function( test_case )
	local out = {
		"\n\n=== dmc_websockets: doTest ===\n",
		"%s : %s\n\n" % { test_case.id, test_case.desc }
	}
	print( table.concat( out, '' ) )

	if ws then
		ws:removeEventListener( ws.EVENT, ws_handler )
		ws:removeSelf()
	end

	-- create new socket
	ws = WebSockets{
		uri='ws://192.168.0.102:9001/runCase?case=%s&agent=%s' % { test_case.index, 'dmc_websockets/1.1' },
		throttle=WebSockets.OFF,
		-- port=9002
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
		print( "dmc_websockets: Testing is complete" )
	end
end


--====================================================================--
-- Main Functions

gotoNextTest()

--====================================================================--
-- Async Sockets Basic
--
-- Tests the Sockets library, async style
--
-- by David McCuskey
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2014 David McCuskey. All Rights Reserved.
--====================================================================--


print("===================================================================")


--===================================================================--
-- Imports
--===================================================================--

local Sockets = require 'dmc_library.dmc_sockets'


--====================================================================--
-- Setup, Constants
--====================================================================--

local host, port = 'docs.davidmccuskey.com', 80
local sock


--====================================================================--
-- Support Functions
--====================================================================--


-- make up a generic request for the web server
--
local function sendRequest()

	local req_t, req
	local bytes, err

	local req_t = {
		"GET / HTTP/1.1\r\n",
		"Host: " .. host .. "\r\n",
		"User-Agent: DMC Sockets " .. Sockets.VERSION .. "\r\n",
		"\r\n"
	}
	req = table.concat( req_t, "" )
	bytes, err = sock:send( req )

end

-- to show non-blocking aspects
local function startObjectMotion()

	local leftX, rightX = 10, 300
	local TIME = 2000

	local o = display.newRect( leftX, 200, 20, 20 )
	local moveRight, moveLeft

	moveRight = function()
		transition.to( o, { x=rightX, time=TIME, onComplete=moveLeft } )
	end

	moveLeft = function()
	transition.to( o, { x=leftX, time=TIME, onComplete=moveRight } )
	end

	moveRight()

end


--====================================================================--
-- Main
--====================================================================--

local function main()

	local onConnect, dataCallback, newlineCallback

	onConnect = function( event )
		if event.status == sock.CONNECTED then
			print("=== Connection Established ===")

			sendRequest()

			print("Reading Data\n\n")
			-- sock:receive( '*l', dataCallback )
			sock:receiveUntilNewline( newlineCallback )

		elseif event.status == sock.CLOSED then
			print("=== Connection Closed ===\n\n")

			timer.performWithDelay( 4000, function() print("Reconnecting\n\n") ; sock:reconnect( { onConnect=onConnect } ) end )

		else
			print("=== Connection Error ===")
			print( event.emsg )

		end
	end

	dataCallback = function( event )
		print("== Data Handler ==")
		print( '>>', event.data, event.emsg )
	end

	newlineCallback = function( event )
		print("== Newline Handler ==")
		event = event or {}

		if not event.data then
			print( event.emsg )

		else
			print("Received Data:\n")
			for i,v in ipairs( event.data ) do
				print(i,v)
			end
			print("\n")

		end
	end

	print("Starting Connection")
	sock = Sockets:create( Sockets.ATCP )
	sock:connect( host, port, { onConnect=onConnect } )

end

main()
startObjectMotion()


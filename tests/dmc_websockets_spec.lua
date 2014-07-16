module(..., package.seeall)


--====================================================================--
-- Test: dmc_websockets
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Testing Setup
--====================================================================--

local ws_handshake

function suite_setup()
	require( "dmc_corona_boot" )
	ws_handshake = require "dmc_websockets.handshake"
end


function test_buildServerKey()
	local key = 'dGhlIHNhbXBsZSBub25jZQ=='
	local srvr_key = 's3pPLMBiTxaQ9kYGzzhZRbK+xOo='
	assert_equal( ws_handshake._buildServerKey( key ), srvr_key, "should be equal" )
end

function test_checkResponse_errors()
	assert_error( function() ws_handshake.checkResponse( nil, nil ) end, "should be error" )
	assert_error( function() ws_handshake.checkResponse( {}, nil ) end, "should be error" )
end

function test_checkResponse_badHeaders()
	local key = 'rzcDgS8mDBqtJSCHyPBT3g=='
	local response = {
		'HTTP/1.1 200 OK',
		'Cache-Control: max-age=900',
		'Content-Type: text/html; charset=utf-8',
		'Server: Microsoft-IIS/7.5',
		'X-AspNet-Version: 4.0.30319',
		'X-Powered-By: ASP.NET',
		'Date: Mon, 14 Jul 2014 21:15:27 GMT',
		'Content-Length: 225',
		'Age: 0',
		''
	}
	assert_false( ws_handshake.checkResponse( response, key ), "should be false" )

	response = {
		'HTTP/1.1 101 Switching Protocols',
		'Cache-Control: max-age=900',
		'Content-Type: text/html; charset=utf-8',
		''
	}
	assert_false( ws_handshake.checkResponse( response, key ), "should be false" )

	response = {
		'HTTP/1.1 101 Switching Protocols',
		'Upgrade: websocket',
		'Content-Type: text/html; charset=utf-8',
		'Server: Microsoft-IIS/7.5',
		''
	}
	assert_false( ws_handshake.checkResponse( response, key ), "should be false" )

	response = {
		'HTTP/1.1 101 Switching Protocols',
		'Upgrade: websocket',
		'Content-Type: text/html; charset=utf-8',
		'Server: Microsoft-IIS/7.5',
		'Connection: Upgrade',
		''
	}
	assert_false( ws_handshake.checkResponse( response, key ), "should be false" )

end


function test_checkResponse_goodHeaders()
	local key = 'dGhlIHNhbXBsZSBub25jZQ=='
	local response = {
		'HTTP/1.1 101 Switching Protocols',
		'Upgrade: websocket',
		'Content-Type: text/html; charset=utf-8',
		'Server: Microsoft-IIS/7.5',
		'Connection: Upgrade',
		'Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
		'Sec-WebSocket-Protocol: 7',
		''
	}
	assert_true( ws_handshake.checkResponse( response, key ), "should be true" )

	key = 'MSg0ucuFeYQT7Bb1/FjgDg=='
	response = {
		'HTTP/1.1 101 Switching Protocols',
		'Upgrade: websocket',
		'Connection: Upgrade',
		'Sec-WebSocket-Accept: mqJX00qwTkOd8zz677Gg+vlqaw8=',
		'Sec-WebSocket-Protocol: 7',
		''
	}
	assert_true( ws_handshake.checkResponse( response, key ), "should be true" )

end

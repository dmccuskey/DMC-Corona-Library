--====================================================================--
-- tcp.lua (part of dmc_sockets.lua)
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_sockets.lua
--====================================================================--

--[[

Copyright (C) 2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
-- Boot Support Methods
--====================================================================--

local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end



--====================================================================--
-- DMC Library Config
--====================================================================--

local dmc_lib_data, dmc_lib_info, dmc_lib_location

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_library_boot" ) end ) then
	_G.__dmc_library = {
		dmc_library={
			location = ''
		},
		func = {
			find=function( name )
				local loc = ''
				if dmc_lib_data[name] and dmc_lib_data[name].location then
					loc = dmc_lib_data[name].location
				else
					loc = dmc_lib_info.location
				end
				if loc ~= '' and string.sub( loc, -1 ) ~= '.' then
					loc = loc .. '.'
				end
				return loc .. name
			end
		}
	}
end

dmc_lib_data = _G.__dmc_library
dmc_lib_func = dmc_lib_data.func
dmc_lib_info = dmc_lib_data.dmc_library
dmc_lib_location = dmc_lib_info.location



--====================================================================--
-- DMC Library : tcp
--====================================================================--



--====================================================================--
-- Imports
--====================================================================--

local Objects = require( dmc_lib_func.find('dmc_objects') )
local socket = require 'socket'


--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase

-- local control of development functionality
local LOCAL_DEBUG = false


--====================================================================--
-- TCP Socket Class
--====================================================================--

local TCPSocket = inheritsFrom( CoronaBase )
TCPSocket.NAME = "TCP Socket Class"


--== Class Constants

-- Connection-Status Constants

TCPSocket.NO_SOCKET = 'no_socket'
TCPSocket.NOT_CONNECTED = 'socket_not_connected'
TCPSocket.CONNECTED = 'socket_connected'
TCPSocket.CLOSED = 'socket_closed'


-- Event Constants

TCPSocket.EVENT = 'tcp_socket_event'

TCPSocket.CONNECT = 'connect_event'
TCPSocket.READ = 'read_event'
TCPSocket.WRITE = 'write_event'



--====================================================================--
--== Start: Setup DMC Objects

function TCPSocket:_init( params )
	-- print( "TCPSocket:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	self._host = nil
	self._port = nil

	-- self._buffer = {} -- table with data
	-- self._buffer_size = 0
	self._buffer = "" -- string

	self._status = nil

	self._socket = nil
	self._master = params.master

end

function TCPSocket:_initComplete()
	-- print( "TCPSocket:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	self:_createSocket()

end
function TCPSocket:_undoInitComplete()
	-- print( "TCPSocket:_undoInitComplete" )

	self:_removeSocket()

	--==--
	self:superCall( "_undoInitComplete" )
end

--== END: Setup DMC Objects
--====================================================================--




--====================================================================--
--== Public Methods



function TCPSocket.__getters:buffer_size()
	return #self._buffer
end

function TCPSocket:clearBuffer()
	-- print( 'TCPSocket:clearBuffer' )
	self._buffer = ""
end


function TCPSocket:reconnect()
	-- print( 'TCPSocket:reconnect' )
	local params = {}
	self:connect( self._host, self._port, params )
end

function TCPSocket:connect( host, port, params )
	-- print( 'TCPSocket:connect', host, port, params )
	params = params or {}
	--==--

	self._host = host
	self._port = port

	local evt = {}

	if self._status == TCPSocket.CONNECTED then

		evt.status = self._status
		evt.msg = "Socket is already connected"

		warning( evt.msg )

		self:_dispatchEvent( self.CONNECT, evt, { merge=true } )
		return
	end

	self:_createSocket()

	local success, emsg = self._socket:connect( host, port )

	if success then
		self._status = TCPSocket.CONNECTED
		self._socket:settimeout(0)

		evt.status = self._status
		evt.msg = nil

		self:_dispatchEvent( self.CONNECT, evt, { merge=true } )

	else
		self._status = TCPSocket.NOT_CONNECTED

		evt.status = self._status
		evt.msg = nil

		self:_dispatchEvent( self.CONNECT, evt, { merge=true } )

	end

end


function TCPSocket:send( data )
	-- print( 'TCPSocket:send', #data )
	return self._socket:send( data )
end


function TCPSocket:unreceive( data )
	-- print( 'TCPSocket:unreceive', #data )
	self._buffer = table.concat( { data, self._buffer } )
end

function TCPSocket:receive( ... )
	-- print( 'TCPSocket:receive' )

	local args = ...
	local buffer = self._buffer

	local data

	if type( args ) == 'string' and args == '*a' then
		data = buffer
		self._buffer = ""

	elseif type( args ) == 'number' and #buffer >= args then
		data = string.sub( buffer, 1, args )
		self._buffer = string.sub( buffer, args+1 )

	elseif type( args ) == 'string' and args == '*l' then
		local ret = '\r\n'
		local lret = #ret
		local beg, _ = string.find( buffer, ret )

		if beg == 1 then
			data = ""
			self._buffer = string.sub( buffer, beg+lret )
		elseif beg then
			data = string.sub( buffer, 1, beg )
			self._buffer = string.sub( buffer, beg+lret )
		end

	end

	-- print( data, self._buffer, self.buffer_size )

	return data
end


function TCPSocket:getstats( ... )
	-- print( 'TCPSocket:getstats' )
	return self._socket:getstats()
end


function TCPSocket:close()
	-- print( 'TCPSocket:close' )

	local evt = {}

	if self._status == TCPSocket.CLOSED then
		evt.status = self._status
		evt.msg = "Socket is already closed"

		notice( evt.msg )

		self:_dispatchEvent( self.CONNECT, evt, { merge=true } )

		return
	end

	self._socket:close()
	self._status = TCPSocket.CLOSED

	evt.status = self._status
	evt.msg = nil

	self:_dispatchEvent( self.CONNECT, evt, { merge=true } )

end




--====================================================================--
--== Private Methods



function TCPSocket:_createSocket()
	-- print( 'TCPSocket:_createSocket' )

	-- we already have unused socket available
	if self._status == TCPSocket.NOT_CONNECTED then return end

	self:_removeSocket()

	self._socket = socket.tcp()
	self._status = TCPSocket.NOT_CONNECTED

	self._socket:settimeout()
	self._master:_connect( self )

end


function TCPSocket:_removeSocket()
	-- print( 'TCPSocket:_createSocket' )

	if not self._socket then return end

	self:close()
	self._master:_disconnect( self )

	self._socket = nil
	self._status = TCPSocket.NO_SOCKET

end


function TCPSocket:_readStatus( status )
	-- print( 'TCPSocket:_readStatus', status )

	local buff_tmp, buff_len

	local bytes, emsg, partial = self._socket:receive( '*a' )
	-- print( 'dataReady', bytes, emsg, partial )

	if bytes == nil and emsg == 'closed' then
		self:close()
		return
	end

	if bytes ~= nil then
		buff_tmp = { self._buffer, bytes }

	elseif emsg == 'timeout' and partial then
		buff_tmp = { self._buffer, partial }

	end

	if buff_tmp then
		self._buffer = table.concat( buff_tmp )
	end

	buff_len = #self._buffer
	if buff_len then

		local evt = {
			status = self._status,
			bytes = buff_len
		}
		self:_dispatchEvent( self.READ, evt, { merge=true } )

	end

end


function TCPSocket:_writeStatus( status )
	print( 'TCPSocket:_writeStatus', status )

	-- TODO: hook up write notification
	-- this is likely to be different than the read
end




--====================================================================--
--== Event Handlers

-- none




return TCPSocket

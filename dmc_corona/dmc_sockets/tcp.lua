--====================================================================--
-- dmc_corona/dmc_sockets/tcp.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2014-2015 David McCuskey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]



--====================================================================--
--== DMC Corona Library : TCP
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.0"



--====================================================================--
--== Imports

local Objects = require 'dmc_objects'
local socket = require 'socket'
local Utils = require 'dmc_utils'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local tconcat = table.concat

local LOCAL_DEBUG = false



--====================================================================--
--== TCP Socket Class
--====================================================================--


local TCPSocket = newClass( ObjectBase, { name="TCP Socket" } )

--== Class Constants

-- Connection-Status Constants

TCPSocket.NO_SOCKET = 'no_socket'
TCPSocket.NOT_CONNECTED = 'socket_not_connected'
TCPSocket.CONNECTED = 'socket_connected'
TCPSocket.CLOSED = 'socket_closed'

-- Lua Socket Error Msg Constants

TCPSocket.ERR_CONNECTED = 'already connected'
TCPSocket.ERR_CONNECTION = 'Operation already in progress'
TCPSocket.ERR_TIMEOUT = 'timeout'
TCPSocket.SSL_READTIMEOUT = 'wantread'
TCPSocket.ERR_CLOSED = 'already closed'

--== Event Constants

TCPSocket.EVENT = 'tcp_socket_event'

TCPSocket.CONNECT = 'connect_event'
TCPSocket.READ = 'read_event'
TCPSocket.WRITE = 'write_event'


--======================================================--
-- Start: Setup DMC Objects

function TCPSocket:__init__( params )
	-- print( "TCPSocket:__init__" )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	if self.is_class then return end

	assert( params.master, "TCP Socket requires Master")

	--== Create Properties ==--

	self._host = nil
	self._port = nil

	self._status = nil
	self._buffer = "" -- string

	self.secure = false

	--== Object References ==--

	self._socket = nil -- real Lua Socket
	self._master = params.master

end


function TCPSocket:__undoInitComplete__()
	-- print( "TCPSocket:__undoInitComplete__" )

	self:_removeSocket()

	--==--
	self:superCall( '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function TCPSocket.__getters:status()
	return self._status
end

function TCPSocket.__getters:buffer_size()
	return #self._buffer
end

function TCPSocket:clearBuffer()
	-- print( 'TCPSocket:clearBuffer' )
	self._buffer = ""
end


function TCPSocket:reconnect( params )
	-- print( 'TCPSocket:reconnect' )
	params = params or {}
	--==--

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
		evt.emsg = self.ERR_CONNECTED

		-- warning( evt.emsg ) -- waiting for dmc_patch
		-- print( "TCPSocket:connect:: " .. evt.emsg )

		self:dispatchEvent( self.CONNECT, evt, { merge=true } )
		return
	end

	self:_createSocket()

	local success, emsg = self._socket:connect( host, port )
	if LOCAL_DEBUG then
		print( "connect ", success, emsg )
	end

	if success then
		self._status = TCPSocket.CONNECTED
		self._socket:settimeout(0)

		self._master:_connect( self )

		evt.status = self._status
		evt.emsg = nil

		self:dispatchEvent( self.CONNECT, evt, { merge=true } )

	else
		self._status = TCPSocket.NOT_CONNECTED

		evt.status = self._status
		evt.emsg = nil

		self:dispatchEvent( self.CONNECT, evt, { merge=true } )

	end

end


function TCPSocket:send( data )
	-- print( 'TCPSocket:send', #data )
	if LOCAL_DEBUG then
		Utils.hexDump( data )
	end
	return self._socket:send( data )
end


function TCPSocket:unreceive( data )
	-- print( 'TCPSocket:unreceive', #data )
	self._buffer = tconcat( { data, self._buffer } )
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
		evt.emsg = self.ERR_CLOSED

		-- notice( evt.emsg ) -- waiting for dmc_patch
		-- print( "TCPSocket:close :" .. evt.emsg )

		-- self:dispatchEvent( self.CONNECT, evt, { merge=true } )

		return
	end

	self:_closeSocket()
	self:_removeSocket()

end



--====================================================================--
--== Private Methods


function TCPSocket:_createSocket( params )
	-- print( 'TCPSocket:_createSocket' )
	params = params or {}
	--==--
	-- we already have unused socket available
	if self._status == TCPSocket.NOT_CONNECTED then return end

	self:_removeSocket()

	self._socket = socket.tcp()
	self._status = TCPSocket.NOT_CONNECTED

	self._socket:settimeout( params.timeout )

end


function TCPSocket:_closeSocket()
	-- print( 'TCPSocket:_closeSocket' )

	local evt = {}

	self._socket:close()
	self._status = TCPSocket.CLOSED

	evt.status = self._status
	evt.emsg = nil

	self:_closeSocketDispatch( evt )

end


function TCPSocket:_closeSocketDispatch( evt )
	-- print( 'TCPSocket:_closeSocketDispatch', evt )
	self:dispatchEvent( self.CONNECT, evt, { merge=true } )
end


function TCPSocket:_removeSocket()
	-- print( 'TCPSocket:_removeSocket' )

	if not self._socket then return end

	self._master:_disconnect( self )

	self._socket = nil
	self._status = TCPSocket.NO_SOCKET

end


function TCPSocket:_readStatus( status )
	-- print( 'TCPSocket:_readStatus', status )

	local buff_tmp, buff_len

	local bytes, status, partial = self._socket:receive( '*a' )
	if LOCAL_DEBUG then
		print( 'TCP:dataReady', bytes, status, partial )
	end

	if bytes == nil and status == 'closed' then
		self:close()
		return
	end

	if bytes ~= nil then
		buff_tmp = { self._buffer, bytes }

	elseif not self.secure and status == self.ERR_TIMEOUT and partial then
		buff_tmp = { self._buffer, partial }

	elseif self.secure and status==self.SSL_READTIMEOUT and partial then
		buff_tmp = { self._buffer, partial }

	end

	if buff_tmp then
		self._buffer = tconcat( buff_tmp )
	end

	if LOCAL_DEBUG then
		Utils.hexDump( self._buffer )
	end

	self:_doAfterReadAction()

end


function TCPSocket:_doAfterReadAction()
	-- print( 'TCPSocket:_doAfterReadAction' )
	local buff_len = #self._buffer
	if buff_len > 0 then
		local evt = {
			status = self._status,
			bytes = buff_len
		}
		self:dispatchEvent( self.READ, evt, { merge=true } )
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

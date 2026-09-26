--====================================================================--
-- dmc_sockets/async_tcp.lua
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
--== DMC Corona Library : Async TCP
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.4.0"



--====================================================================--
--== Imports


local Objects = require 'lib.dmc_lua.lua_objects'
local socket = require 'socket'
local SSLParams = require 'dmc_sockets.ssl_params'
local TCPSocket = require 'dmc_sockets.tcp'



--====================================================================--
--== Setup, Constants


local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove

local ssl

local LOCAL_DEBUG = false



--====================================================================--
--== Support Functions


-- use the Corona plugins, or plain luasec outside Corona
--
local function loadSSL()
	local success = pcall( function()
		local openssl = require 'plugin.openssl'
		ssl = require 'plugin_luasec_ssl'
	end )
	if not success then ssl = require 'ssl' end
end



--====================================================================--
--== Async TCP Socket Class
--====================================================================--


local ATCPSocket = newClass( TCPSocket, { name="Async TCP Socket" } )


--======================================================--
-- Start: Setup Lua Objects

function ATCPSocket:__init__( params )
	-- print( "ATCPSocket:__init__" )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._timeout = 6000

	self.__coroutine_queue_active = false
	self._coroutine_queue = {}

	self._read_in_process = false

	-- data not yet accepted by the OS, sent on later frames
	-- list of { data=<string>, index=<next byte>, callback=<func> }
	self._write_queue = {}
	self._write_handler = nil

	self._ssl_params = params.ssl_params

	--== Object References ==--

end

function ATCPSocket:__initComplete__()
	-- print( "ATCPSocket:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--

	self.ssl_params = self._ssl_params -- use setter
end

-- END: Setup Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


function ATCPSocket.__getters:timeout( value )
	self._timeout = value
end


function ATCPSocket.__setters:ssl_params( value )
	-- print( "ATCPSocket.__setters:ssl_params", value )
	assert( value==nil or type(value)=='table', "ATCPSocket.ssl_params incorrect value" )
	--==--

	if value == nil then
		-- TODO: properly destroy
		self._ssl_params = nil
	elseif value.isa and value:isa( SSLParams ) then
		self._ssl_params = value
	else
		self._ssl_params = SSLParams:new( value )
	end

end

function ATCPSocket.__getters:ssl_params( value )
	-- print( "ATCPSocket.__getters:ssl_params", is_secure )
	return self._ssl_params
end


function ATCPSocket.__setters:secure( is_secure )
	-- print( "ATCPSocket.__setters:secure", is_secure )
	if not is_secure then
		self._ssl_params = nil
	elseif is_secure and self._ssl_params == nil then
		self._ssl_params = SSLParams:new()
	end
	if is_secure and not ssl then loadSSL() end
end

function ATCPSocket.__getters:secure()
	-- print( "ATCPSocket.__getters:secure" )
	return (self._ssl_params ~= nil)
end


function ATCPSocket:connect( host, port, params )
	-- print( 'ATCPSocket:connect', host, port, params )
	params = params or {}
	--==--

	self._host = host
	self._port = port
	self._onConnect = params.onConnect
	self._onData = params.onData

	if self._status == ATCPSocket.CONNECTED then
		local evt = {
			type=self.CONNECT,
			emsg=self.ERR_CONNECTED
		}
		if self._onConnect then self._onConnect( evt ) end
		return
	end

	self:_createSocket( { timeout=0 } )

	local f = function()
		local beg_time = system.getTimer()
		local timeout, time_diff = self._timeout, 0
		local evt = {}

		repeat

			local success, emsg = self._socket:connect( host, port )
			if LOCAL_DEBUG then
				print( "dmc.ATCP: connect", success, emsg )
			end
			-- messages:
			-- nil	timeout
			-- nil	Operation already in progress
			-- nil	already connected

			if success or emsg == self.ERR_CONNECTED then
				self._status = self.CONNECTED
				evt.type = self.CONNECT
				evt.status = self._status
				evt.emsg = emsg

				if self.secure == true then

					local sock, emsg = ssl.wrap( self._socket, self.ssl_params )

					if sock then
						self._socket = sock
						-- send the host name (SNI); servers behind
						-- shared hosts and CDNs reject handshakes without it
						if sock.sni then sock:sni( host ) end
					else
						evt.isError = true
						evt.emsg = emsg
						if self._onConnect then self._onConnect( evt ) end
						return
					end

					local result, emsg = self._socket:dohandshake()

					if not result then
						evt.isError = true
						evt.emsg = emsg
						if self._onConnect then self._onConnect( evt ) end
						return
					end

					-- need to re-set for wrapped socket. socket options
					-- were set on the plain socket; wrapped ones have no setoption()
					self._socket:settimeout( 0 )

				end

				self._master:_connect( self )

				self:_removeCoroutineFromQueue()

				if self._onConnect then self._onConnect( evt ) end

			else
				coroutine.yield()

			end

			time_diff = system.getTimer() - beg_time

		until time_diff > timeout or self._status == self.CONNECTED

		if self._status ~= self.CONNECTED then
			self._status = self.NOT_CONNECTED
			evt.type = self.CONNECT
			evt.status = self._status
			evt.emsg = self.ERR_TIMEOUT

			self:_removeCoroutineFromQueue()

			if self._onConnect then self._onConnect( evt ) end
		end

	end

	self:_addCoroutineToQueue( f )
end


-- send()
-- a non-blocking send may only write part of the data, so anything
-- left over is queued and written on following frames. callback is
-- called when all of the data has been sent, or on error.
--
function ATCPSocket:send( data, callback )
	-- print( 'ATCPSocket:send', #data, callback )
	tinsert( self._write_queue, { data=data, index=1, callback=callback } )
	self:_processWriteQueue()
end


function ATCPSocket:close()
	-- print( 'ATCPSocket:close' )
	self:_stopWriteHandler()
	self._write_queue = {}
	self:superCall( 'close' )
end


function ATCPSocket:receive( option, callback )
	-- print( 'ATCPSocket:receive', option, callback )

	if not callback or type( callback ) ~= 'function' then return end

	local buffer = self._buffer

	local evt = {}
	local data

	if type( option ) == 'string' and option == '*a' then
		data = buffer
		self._buffer = ""
		evt.data, evt.emsg = data, nil
		callback( evt )
		return

	elseif type( option ) == 'number' and #buffer >= option then
		data = string.sub( buffer, 1, option )
		self._buffer = string.sub( buffer, option+1 )

		callback( { data=data, emsg=nil } )

	elseif type( option ) == 'string' and option == '*l' then

		-- create coroutine function
		local f = function( not_coroutine )

			local beg_time = system.getTimer()
			local timeout, time_diff = self._timeout, 0

			repeat

				data = self:superCall( "receive", option )

				if not_coroutine then return data end

				if not data then
					coroutine.yield()
				else
					self._read_in_process = false
					evt.data, evt.emsg = data, nil
					callback( evt )
				end

				time_diff = system.getTimer() - beg_time

			until data or time_diff > timeout

			if not data then
				self._read_in_process = false
				evt.data, evt.emsg = nil, self.ERR_TIMEOUT
				callback( evt )
			end

		end

		self._read_in_process = true

		data = f( true )
		if data then
			self._read_in_process = false
			evt.data, evt.emsg = data, nil
			callback( evt )
		else
			local co = coroutine.create( f )
			table.insert( self._coroutine_queue, co )
		end

	end

end


function ATCPSocket:receiveUntilNewline( callback )
	-- print( 'ATCPSocket:receiveUntilNewline' )
	assert( type(callback)=='function', "receiveUntilNewline: expected function callback" )
	--==--

	local data_list = {}
	local evt = {}

	-- create coroutine function
	local doDataCall = function( not_coroutine )
		-- print( "do data call", not_coroutine )

		local beg_time = system.getTimer()
		local timeout, time_diff = self._timeout, 0

		repeat

			local data = self:superCall( 'receive', '*l' )

			-- data handling
			if data then
				tinsert( data_list, data )

				if data == '' then
					if not_coroutine then
						return true
					else
						self:_removeCoroutineFromQueue()

						evt.data, evt.emsg = data_list, nil
						callback( evt )
					end
				end

			end

			-- control
			if not data then
				if not_coroutine then
					return false
				else
					coroutine.yield()
				end
			end

			time_diff = system.getTimer() - beg_time

		until data == '' or time_diff > timeout

		self:_removeCoroutineFromQueue()

		if data_list[#data_list] ~= '' then
			if #data_list > 0 then
				local str = tconcat( data_list, '\r\n' )
				self:unreceive( str )
			end
			evt.data, evt.emsg = nil, self.ERR_TIMEOUT
			callback( evt )
		end

	end -- doDataCall


	-- run doDataCall, see if we have data now
	-- otherwise put in coroutine loop

	if doDataCall( true ) == true then
		evt.data, evt.emsg = data_list, nil
		callback( evt )

	else
		if #data_list > 0 then
			local str = tconcat( data_list, '\r\n' )
			self:unreceive( str )
		end

		self:_addCoroutineToQueue( doDataCall )
	end

end



--====================================================================--
--== Private Methods


function ATCPSocket:_processWriteQueue()
	-- print( 'ATCPSocket:_processWriteQueue', #self._write_queue )
	local queue = self._write_queue

	while #queue > 0 do
		local rec = queue[1]
		local sock = self._socket
		local last, emsg, partial

		if sock then
			last, emsg, partial = sock:send( rec.data, rec.index )
		else
			emsg = 'closed'
		end

		if last then
			-- all sent
			tremove( queue, 1 )
			if rec.callback then rec.callback( {} ) end

		elseif emsg == self.ERR_TIMEOUT or emsg == 'wantwrite' then
			-- OS buffer is full, try again next frame
			rec.index = ( partial or rec.index-1 ) + 1
			self:_startWriteHandler()
			return

		else
			-- connection error, fail everything waiting
			self._write_queue = {}
			self:_stopWriteHandler()
			for _, r in ipairs( queue ) do
				if r.callback then r.callback( { isError=true, emsg=emsg } ) end
			end
			return
		end
	end

	self:_stopWriteHandler()
end

function ATCPSocket:_startWriteHandler()
	if self._write_handler then return end
	self._write_handler = function() self:_processWriteQueue() end
	Runtime:addEventListener( 'enterFrame', self._write_handler )
end

function ATCPSocket:_stopWriteHandler()
	if not self._write_handler then return end
	Runtime:removeEventListener( 'enterFrame', self._write_handler )
	self._write_handler = nil
end


function ATCPSocket:_closeSocketDispatch( evt )
	-- print( 'ATCPSocket:_closeSocketDispatch', evt )
	evt.type = self.CONNECT
	if self._onConnect then self._onConnect( evt ) end
end


function ATCPSocket:_doAfterReadAction()
	-- print( 'ATCPSocket:_doAfterReadAction' )
	local buff_len = #self._buffer
	if buff_len > 0 then
		self:_processCoroutineQueue()
	end
	buff_len = #self._buffer
	if buff_len > 0 and not self._read_in_process then
		local evt = {
			type=self.READ,
			status = self._status,
			bytes = buff_len
		}
		if self._onData then self._onData( evt ) end
	end

end


function ATCPSocket:_getActiveCoroutine()
	-- print( 'ATCPSocket:_getActiveCoroutine' )
	return self._coroutine_queue[ 1 ]
end

function ATCPSocket:_addCoroutineToQueue( func )
	-- print( 'ATCPSocket:_addCoroutineToQueue' )
	assert( type(func)=='function', "expected function" )
	--==--
	local co = coroutine.create( func )
	tinsert( self._coroutine_queue, co )

	-- if we still have info left, then set listener
	if not self._coroutine_queue_active and #self._coroutine_queue > 0 then
		Runtime:addEventListener( 'enterFrame', self )
		self._coroutine_queue_active = true
	end
end

function ATCPSocket:_removeCoroutineFromQueue()
	-- print( 'ATCPSocket:_removeCoroutineFromQueue' )
	-- assert( type(func)=='function', "expected function" )
	--==--

	if #self._coroutine_queue > 0 then
		tremove( self._coroutine_queue, 1 )
	end

	-- if no more routines, then unset listener
	if #self._coroutine_queue == 0 and self._coroutine_queue_active then
		Runtime:removeEventListener( 'enterFrame', self )
		self._coroutine_queue_active = false
	end
end

function ATCPSocket:_processCoroutineQueue()
	-- print( 'ATCPSocket:_processCoroutineQueue' )

	local co = self:_getActiveCoroutine()
	if co then
		local status, msg = coroutine.resume( co )
		if not status then
			self:_removeCoroutineFromQueue()
			print( "ERROR in async_tcp coroutine" )
			error( msg )
		end
		if coroutine.status( co ) ~= 'dead' then return end
	end

	-- coroutine is finished, remove it
	self:_removeCoroutineFromQueue()
end



--====================================================================--
--== Event Handlers


function ATCPSocket:_socketsEvent_handler( event )
	-- print( 'ATCPSocket:_socketsEvent_handler', event )
	self:_processCoroutineQueue()
end


function ATCPSocket:enterFrame( event )
	-- print( 'ATCPSocket:enterFrame', event )
	self:_processCoroutineQueue()
end



return ATCPSocket

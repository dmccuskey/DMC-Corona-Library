--====================================================================--
-- dmc_sockets.lua
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
-- DMC Library : DMC Sockets
--====================================================================--



--====================================================================--
-- Configuration
--====================================================================--

dmc_lib_data.dmc_sockets = dmc_lib_data.dmc_sockets or {}

local DMC_SOCKETS_DEFAULTS = {
	check_reads=true,
	check_writes=false,
	throttle_level=math.floor( 1000/15 ), -- MEDIUM
}

local dmc_states_data = Utils.extend( dmc_lib_data.dmc_sockets, DMC_SOCKETS_DEFAULTS )


--====================================================================--
-- Imports
--====================================================================--

local Objects = require( dmc_lib_func.find('dmc_objects') )
local Utils = require( dmc_lib_func.find('dmc_utils') )
local socket = require 'socket'

local tcp_socket = require( dmc_lib_func.find('dmc_sockets.tcp') )
local atcp_socket = require( dmc_lib_func.find('dmc_sockets.atcp') )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase

-- local control of development functionality
local LOCAL_DEBUG = false

local Singleton = nil


--====================================================================--
-- Sockets Class
--====================================================================--

local Sockets = inheritsFrom( CoronaBase )
Sockets.NAME = "Sockets Class"

Sockets.VERSION = VERSION

--== Class Constants

Sockets.NO_BLOCK = 0
Sockets.TCP = 'tcp'
Sockets.ATCP = 'atcp'

-- throttle socket checks, milliseconds delay
Sockets.OFF = 0
Sockets.LOW = math.floor( 1000/30 )  -- ie, 30 FPS
Sockets.MEDIUM = math.floor( 1000/15 )  -- ie, 15 FPS
Sockets.HIGH = math.floor( 1000/1 )  -- ie, 1 FPS

Sockets.DEFAULT = Sockets.MEDIUM



--====================================================================--
--== Start: Setup DMC Objects

function Sockets:_init( params )
	-- print( "Sockets:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Create Properties ==--

	self._sockets = {} -- socket objects, keyed by object
	self._raw_socks = {} -- socket objects, keyed by socket
	self._raw_socks_list = {} -- socket

	self._check_read = nil
	self._check_write = nil

	self._socket_check_is_active = false
	self._socket_check_handler = nil

	--== Object References ==--

	-- none

end
function Sockets:_undoInit()
	-- print( "Sockets:_undoInit" )

	self._sockets = nil
	self._raw_socks = nil
	self._raw_socks_list = nil

	--==--
	self:superCall( "_undoInit" )
end

function Sockets:_initComplete()
	-- print( "Sockets:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	-- initialize using setters
	self.check_reads = dmc_states_data.check_reads
	self.check_writes = dmc_states_data.check_writes

	if type( dmc_states_data.throttle_level ) == 'number' then
		self.throttle = dmc_states_data.throttle_level
	else
		self.throttle = Sockets.DEFAULT
	end

end
function Sockets:_undoInitComplete()
	-- print( "Sockets:_undoInitComplete" )

	self:_removeSockets()

	--==--
	self:superCall( "_undoInitComplete" )
end

--== END: Setup DMC Objects
--====================================================================--




--====================================================================--
--== Public Methods



function Sockets.__setters:throttle( value )
	-- print( 'Sockets.__setters:check_reads', value )

	--== Sanity Check

	if type( value ) == 'string' then
		value = tonumber( value )
		if value == nil then value = Sockets.DEFAULT end
	elseif type( value ) ~= 'number' then
		value = Sockets.DEFAULT
	end

	local f

	if value == self.OFF then
		f = self:createCallback( self._checkConnections )
	else
		f = self:_createSocketCheckHandler( value )
	end

	-- using setter
	self._socketCheck_handler = f

end


-- whether to check socket read availability
--
function Sockets.__setters:check_reads( value )
	-- print( 'Sockets.__setters:check_reads', value )
	if value then
		self._check_read = self._raw_socks_list
	else
		self._check_read = nil
	end
end

-- whether to check socket write availability
--
function Sockets.__setters:check_writes( value )
	-- print( 'Sockets.__setters:check_writes', value )
	if value then
		self._check_write = self._raw_socks_list
	else
		self._check_write = nil
	end
end


function Sockets:create( s_type, params )
	-- print( 'Sockets:create', s_type, params )
	params = params or {}
	--==--

	if s_type == Sockets.TCP then
		return tcp_socket:new( { master=self } )

	elseif s_type == Sockets.ATCP then
		return atcp_socket:new( { master=self } )

	elseif s_type == Sockets.UDP then
		error( "UDP is not yet available" )

	else
		error( "Uknown socket type: %s" .. tostring( s_type ) )
	end

end




--====================================================================--
--== Private Methods



-- getter/setter: activate enterFrame for socket check
--
function Sockets.__getters:check_is_active()
	return self._socket_check_is_active
end

-- @param value boolean
function Sockets.__setters:check_is_active( value )
	-- print( 'Sockets.__setters:check_is_active', value )

	local f = self._socketCheck_handler

	if self._socket_check_is_active == value then return end

	if value == true and f then
		Runtime:addEventListener( 'enterFrame', f )
	elseif f then
		Runtime:removeEventListener( 'enterFrame', f )
	end

	self._socket_check_is_active = value

end


-- getter/setter: socket check handler function
function Sockets.__getters:_socketCheck_handler()
	return self._socket_check_handler
end

-- @param value function
function Sockets.__setters:_socketCheck_handler( func )

	if self.check_is_active then
		Runtime:removeEventListener( 'enterFrame', self._socket_check_handler )
		Runtime:addEventListener( 'enterFrame', func )
	end

	self._socket_check_handler = func

end


-- @param socket DMC TCP Socket
function Sockets:_connect( socket )
	-- print( 'Sockets:_connect', socket )
	self:_addSocket( socket )
end

-- @param socket DMC TCP Socket
function Sockets:_disconnect( socket )
	-- print( 'Sockets:_disconnect', socket )
	self:_removeSocket( socket )
end


-- TODO: check this
function Sockets:_removeSockets()
	-- print( "Sockets:_removeSockets" )

	for i = #self._sockets, 1, -1 do
		-- local s = table.remove( self._sockets, 1 )
		local s = self._sockets[ i ]
		self:_removeSocket( s )
	end

end


function Sockets:_addSocket( socket )
	-- print( "Sockets:_addSocket", socket )

	local raw_sock = socket._socket
	local key

	-- save TCP lookup
	key = tostring( socket )
	self._sockets[ key ] = socket

	-- save socket lookup
	key = tostring( raw_sock )
	-- need to modify key, because user-data changes after socket connect
	key = string.gsub( key, 'master', 'client' )
	self._raw_socks[ key ] = socket

	-- save raw socket in list
	table.insert( self._raw_socks_list, raw_sock )

	if #self._raw_socks_list then
		self.check_is_active = true
	end

end


function Sockets:_removeSocket( socket )
	-- print( "Sockets:_removeSocket", socket )

	local raw_sock = socket._socket
	local key

	Utils.removeFromTable( self._raw_socks_list, raw_sock )

	key = tostring( raw_sock )
	self._raw_socks[ key ] = nil

	key = tostring( socket )
	self._sockets[ key ] = nil

	if #self._raw_socks_list == 0 then
		self.check_is_active = false
	end

end


function Sockets:_checkConnections()
	-- print( "Sockets:_checkConnections" )

	local s_read, s_write, err = socket.select( self._check_read, self._check_write, Sockets.NO_BLOCK )

	if err ~= nil then return end

	for i, rs in ipairs( s_read ) do
		-- print( i, rs )
		local socket = self._raw_socks[ tostring( rs ) ]
		socket:_readStatus( 'ok' )
	end

	for i, rs in ipairs( s_write ) do
		-- print( i, rs )
		local socket = self._raw_socks[ tostring( rs ) ]
		socket:_writeStatus( 'ok' )
	end

end






--====================================================================--
--== Event Handlers



function Sockets:_createSocketCheckHandler( value )
	-- print("Sockets:_createSocketCheckHandler", value )
	local timeout = value
	local last_check = system.getTimer()

	local f = function( event )
		local current_time = system.getTimer()
		if current_time - last_check > timeout then
			self:_checkConnections()
			last_check = current_time
		end

	end

	return f

end




--====================================================================--
--== Create Socket Class Singleton

local Singleton = Sockets:new()

return Singleton

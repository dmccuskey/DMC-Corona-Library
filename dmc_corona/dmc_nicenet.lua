--====================================================================--
-- dmc_nicenet.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_nicenet.lua
--====================================================================--

--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

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



--====================================================================--
-- DMC Corona Library : DMC Nice Net
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.1.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


--====================================================================--
-- Support Functions

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
-- Configuration

local dmc_lib_data, dmc_lib_info

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_corona_boot" ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_library



--====================================================================--
-- DMC Nice Net
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_nicenet = dmc_lib_data.dmc_nicenet or {}

local DMC_NICENET_DEFAULTS = {
	cache_is_active=false,
	make_global=false,
}

local dmc_nicenet_data = Utils.extend( dmc_lib_data.dmc_nicenet, DMC_NICENET_DEFAULTS )


--====================================================================--
-- Imports

local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase



--====================================================================--
-- Network Command Class
--====================================================================--


local NetworkCommand = inheritsFrom( CoronaBase )
NetworkCommand.NAME = "Network Command"

--== Class Constants

-- priority constants
NetworkCommand.HIGH = 1
NetworkCommand.MEDIUM = 2
NetworkCommand.LOW = 3

-- priority constants
NetworkCommand.TYPE_DOWNLOAD = 'network_download'
NetworkCommand.TYPE_REQUEST = 'network_request'
NetworkCommand.TYPE_UPLOAD = 'network_upload'

-- priority constants
NetworkCommand.STATE_PENDING = 'state_pending' -- not yet active
NetworkCommand.STATE_UNFULFILLED = 'state_unfulfilled'
NetworkCommand.STATE_RESOLVED = 'state_resolved'
NetworkCommand.STATE_REJECTED = 'state_rejected'
NetworkCommand.STATE_CANCELLED = 'state_cancelled'

--== Event Constants

NetworkCommand.EVENT = "network_command_event"
NetworkCommand.UPDATED = "network_command_updated_event"

NetworkCommand.STATE_UPDATED = "state_updated"
NetworkCommand.PRIORITY_UPDATED = "priority_updated"


--====================================================================--
--== Start: Setup DMC Objects

function NetworkCommand:_init( params )
	--print( "NetworkCommand:_init ", params )
	params = params or {}
	self:superCall( "_init" )
	--==--

	--== Create Properties ==--

	self._type = params.type
	self._state = self.STATE_PENDING
	self._priority = params.priority or self.LOW

	self._command = params.command
	-- url
	-- method
	-- listener
	-- params

	self._net_id = nil -- id from network.* call, can use to cancel

	--== Object References ==--

end


-- _initComplete()
--
function NetworkCommand:_initComplete()
	--print( "NetworkCommand:_initComplete" )
	self:superCall( "_initComplete" )
	--==--
end

function NetworkCommand:_undoInitComplete()
	--print( "NetworkCommand:_undoInitComplete" )
	--==--
	self:superCall( "_undoInitComplete" )
end

--== END: Setup DMC Objects
--====================================================================--


--====================================================================--
--== Public Methods

function NetworkCommand.__getters:key()
	--print( "NetworkCommand.__getters:key" )
	return tostring( self )
end


-- getter/setter, command type
--
function NetworkCommand.__getters:type()
	--print( "NetworkCommand.__getters:type" )
	return self._type
end

-- getter/setter, command priority
--
function NetworkCommand.__getters:priority()
	--print( "NetworkCommand.__getters:priority" )
	return self._priority
end
function NetworkCommand.__setters:priority( value )
	--print( "NetworkCommand.__setters:priority ", value )
	local tmp = self._priority
	self._priority = value
	if tmp ~= value then
		self:_dispatchEvent( NetworkCommand.PRIORITY_UPDATED )
	end
end

-- getter/setter, command state
function NetworkCommand.__getters:state()
	--print( "NetworkCommand.__getters:state" )
	return self._state
end
function NetworkCommand.__setters:state( value )
	--print( "NetworkCommand.__setters:state ", value )
	local tmp = self._state
	self._state = value
	if tmp ~= value then
		self:_dispatchEvent( NetworkCommand.STATE_UPDATED )
	end
end

-- execute
-- start the network call
--
function NetworkCommand:execute()
	--print( "NetworkCommand:execute" )

	local t = self._type
	local p = self._command

	-- Setup basic Corona network.* callback

	local callback = function( event )

		-- set Command Object next state
		if event.isError then
			self.state = self.STATE_REJECTED
		else
			self.state = self.STATE_RESOLVED
		end

		-- do upstream callback
		if p.listener then p.listener( event ) end

	end

	-- Set Command Object active state and
	-- call appropriate Corona network.* function

	self.state = self.STATE_UNFULFILLED

	if t == self.TYPE_REQUEST then
		self._net_id = network.request( p.url, p.method, callback, p.params )

	elseif t == self.TYPE_DOWNLOAD then
		self._net_id = network.download( p.url, p.method, callback, p.params, p.filename, p.basedir )

	elseif t == self.TYPE_UPLOAD then
		self._net_id = network.upload( p.url, p.method, callback, p.params, p.filename, p.basedir, p.contenttype )

	end

end

-- cancel
-- cancel the network call
--
function NetworkCommand:cancel()
	--print( "NetworkCommand:cancel" )
	if self._net_id ~= nil then
		network.cancel( self._net_id )
		self._net_id = nil
	end

	self.state = self.STATE_CANCELLED
end


--====================================================================--
--== Private Methods

-- none


--====================================================================--
--== Event Handlers


-- _dispatchEvent
-- Convenience method used to dispatch custom events
--
-- @params e_type, string, the type of the event
-- @params data, <any>, will be attached to event as event.data
--
function NetworkCommand:_dispatchEvent( e_type, data )
	--print( "NetworkCommand:_dispatchEvent" )

	-- setup custom event
	local e = {
		name = NetworkCommand.EVENT,
		type = e_type,

		target = self,
		data = data
	}

	self:dispatchEvent( e )
end



--====================================================================--
-- Nice Network Base Class
--====================================================================--

local NiceNetwork = inheritsFrom( CoronaBase )
NiceNetwork.NAME = "Nice Network Base"


-- priority constants
NiceNetwork.HIGH = NetworkCommand.HIGH
NiceNetwork.MEDIUM = NetworkCommand.MEDIUM
NiceNetwork.LOW = NetworkCommand.LOW


NiceNetwork.DEFAULT_ACTIVE_QUEUE_LIMIT = 2
NiceNetwork.MIN_ACTIVE_QUEUE_LIMIT = 1


--== Event Constants
NiceNetwork.EVENT = "nicenet_event"
NiceNetwork.QUEUE_UPDATE = "nicenet_queue_updated_event"


--====================================================================--
--== Start: Setup DMC Objects

function NiceNetwork:_init( params )
	--print( "NiceNetwork:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	--== Create Properties ==--

	self._default_priority = params.default_priority or NiceNetwork.LOW

	-- TODO: hook this up to params
	self._active_limit = params.active_queue_limit or self.DEFAULT_ACTIVE_QUEUE_LIMIT

 	-- dict of Active Command Objects, keyed on object raw id
 	self._active_queue = nil
 	-- dict of Pending Command Objects, keyed on object raw id
 	self._pending_queue = nil

	--== Object References ==--

end


-- _initComplete()
--
function NiceNetwork:_initComplete()
	--print( "NiceNetwork:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	-- create data structure
	self._active_queue = {}
	self._pending_queue = {}

end

function NiceNetwork:_undoInitComplete()
	--print( "NiceNetwork:_undoInitComplete" )

	-- remove data structure
	self._active_queue = nil
	self._pending_queue = nil

	--==--
	self:superCall( "_undoInitComplete" )
end

--== END: Setup DMC Objects
--====================================================================--


--====================================================================--
--== Public Methods

-- this is a replacement for Corona network.request()
--[[
network.request( url, method, listener [, params] )
--]]
function NiceNetwork:request( url, method, listener, params )
	--print( "NiceNetwork:request ", url, method )

	--== Setup and create Command object

	local net_params, cmd_params

	-- save parameters for Corona network.* call
	net_params = {
		url=url,
		method=method,
		listener=listener,
		params=params
	}
	-- save parameters for NiceNet Command object
	cmd_params = {
		command=net_params,
		type=NetworkCommand.TYPE_REQUEST,
		priority=self._default_priority
	}

	return self:_insertCommand( cmd_params )
end


-- this is a replacement for Corona network.download()
--[[
network.download( url, method, listener [, params], filename [, baseDirectory] )
--]]
function NiceNetwork:download( url, method, listener, params, filename, basedir )
	--print( "NiceNetwork:download ", url, filename )

	--== Process optional parameters

	-- network params
	if params and type(params) ~= 'table' then
		basedir = filename
		filename = params
		params = nil
	end


	--== Setup and create Command object

	local net_params, cmd_params

	-- save parameters for Corona network.* call
	net_params = {
		url=url,
		method=method,
		listener=listener,
		params=params,
		filename=filename,
		basedir=basedir
	}
	-- save parameters for NiceNet Command object
	cmd_params = {
		command=net_params,
		type=NetworkCommand.TYPE_DOWNLOAD,
		priority=self._default_priority
	}

	return self:_insertCommand( cmd_params )
end


-- this is a replacement for Corona network.upload()
--[[
network.upload( url, method, listener [, params], filename [, baseDirectory] [, contentType] )
--]]
function NiceNetwork:upload( url, method, listener, params, filename, basedir, contenttype )

	--== Process optional parameters

	-- network params
	if params and type(params) ~= 'table' then
		contenttype = basedir
		basedir = filename
		filename = params
		params = nil
	end

	-- base directory
	if basedir and type(basedir) ~= 'userdata' then
		contenttype = basedir
		basedir = nil
	end


	--== Setup and create Command object

	local net_params, cmd_params

	-- save parameters for Corona network.* call
	net_params = {
		url=url,
		method=method,
		listener=listener,
		params=params,
		filename=filename,
		basedir=basedir,
		contenttype=contenttype
	}
	-- save parameters for NiceNet Command object
	cmd_params = {
		command=net_params,
		type=NetworkCommand.TYPE_DOWNLOAD,
		priority=self._default_priority
	}

	return self:_insertCommand( cmd_params )
end


--====================================================================--
--== Private Methods

function NiceNetwork:_insertCommand( params )
	--print( "NiceNetwork:_insertCommand ", command.type )

	local command = NetworkCommand:new( params )
	command:addEventListener( command.EVENT, self )
	self._pending_queue[ command.key ] = command

	self:_processQueue()

	return command
end

function NiceNetwork:_removeCommand( command )
	--print( "NiceNetwork:_insertCommand ", command.type )

	self._active_queue[ command.key ] = nil
	command:removeEventListener( command.EVENT, self )
	command:removeSelf()

	self:_processQueue()
end


function NiceNetwork:_processQueue()
	--print( "NiceNetwork:_processQueue" )

	local pq_status, next_cmd

	if Utils.tableSize( self._active_queue ) < self._active_limit then
		-- we have slots left, checking for pending commands

		-- check status of pending queue
		pq_status = self:_checkStatus( self._pending_queue )

		-- pick next command
		if #pq_status[ NetworkCommand.HIGH ] > 0 then
			next_cmd = pq_status[ NetworkCommand.HIGH ][1]
		elseif #pq_status[ NetworkCommand.MEDIUM ] > 0 then
			next_cmd = pq_status[ NetworkCommand.MEDIUM ][1]
		elseif #pq_status[ NetworkCommand.LOW ] > 0 then
			next_cmd = pq_status[ NetworkCommand.LOW ][1]
		end

		if next_cmd ~= nil then
			self._active_queue[ next_cmd.key ] = next_cmd
			self._pending_queue[ next_cmd.key ] = nil
			next_cmd:execute()
		end
	end

	self:_broadcastStatus()
end


-- provide list of commands in queue for each priority
-- easy to get count of each type from a list
--
function NiceNetwork:_checkStatus( queue )

	local status = {}
	status[ NetworkCommand.LOW ] = {}
	status[ NetworkCommand.MEDIUM ] = {}
	status[ NetworkCommand.HIGH ] = {}

	for _, cmd in pairs( queue ) do
		table.insert( status[ cmd.priority ], cmd )
	end

	return status
end


function NiceNetwork:_broadcastStatus()
	--print( "NiceNetwork:_broadcastStatus" )

	local data = {
		active = self:_checkStatus( self._active_queue ),
		pending = self:_checkStatus( self._pending_queue )
	}

	self:_dispatchEvent( self.QUEUE_UPDATE, data )
end


--====================================================================--
--== Event Handlers

-- this is the network command event handler
-- using name of the event as method name
--
function NiceNetwork:network_command_event( event )
	--print( "NiceNetwork:network_command_event ", event.type )
	local cmd = event.target

	if event.type == cmd.PRIORITY_UPDATED then
		-- count status, and send event
		self:_broadcastStatus()

	elseif event.type == cmd.STATE_UPDATED then

		if cmd.state == cmd.STATE_REJECTED or cmd.state == cmd.STATE_RESOLVED or cmd.state == cmd.STATE_CANCELLED then
			-- remove from Active queue
			self:_removeCommand( cmd )
		end
	end
end


-- _dispatchEvent
-- Convenience method used to dispatch custom events
--
-- @params e_type, string, the type of the event
-- @params data, <any>, will be attached to event as event.data
--
function NiceNetwork:_dispatchEvent( e_type, data )
	--print( "NiceNetwork:_dispatchEvent" )

	-- setup custom event
	local e = {
		name = NiceNetwork.EVENT,
		type = e_type,

		data = data
	}

	self:dispatchEvent( e )
end




return NiceNetwork



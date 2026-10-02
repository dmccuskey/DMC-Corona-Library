--====================================================================--
-- dmc_nicenet.lua
--
-- A better behaved network object for the Corona SDK
--
-- Documentation: https://github.com/dmccuskey/dmc-nicenet
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : DMC NiceNet
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.0.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--



--====================================================================--
--== Configuration


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona

local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== DMC NiceNet
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_nicenet = dmc_lib_data.dmc_nicenet or {}

local DMC_NICENET_DEFAULTS = {
	debug_active=false,
	make_global=false
}

local dmc_nicenet_data = Utils.extend( dmc_lib_data.dmc_nicenet, DMC_NICENET_DEFAULTS )
local Config = dmc_nicenet_data



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase

local tinsert = table.insert

-- the calls NiceNetwork.makeGlobal() replaced in the global network,
-- { network=, request=, download=, upload=, cancel= }, or nil
local Global = nil

-- the four calls makeGlobal() replaces
local GLOBAL_CALLS = { 'request', 'download', 'upload', 'cancel' }



--====================================================================--
--== Network Command Class
--====================================================================--


local NetworkCommand = newClass( ObjectBase, {name="Network Command"} )

--== Class Constants

-- priority constants
NetworkCommand.HIGH = 1
NetworkCommand.MEDIUM = 2
NetworkCommand.LOW = 3

-- type constants
NetworkCommand.TYPE_DOWNLOAD = 'network_download'
NetworkCommand.TYPE_REQUEST = 'network_request'
NetworkCommand.TYPE_UPLOAD = 'network_upload'

-- state constants
NetworkCommand.STATE_PENDING = 'state_pending' -- ie, not yet active
NetworkCommand.STATE_UNFULFILLED = 'state_unfulfilled'
NetworkCommand.STATE_RESOLVED = 'state_resolved'
NetworkCommand.STATE_REJECTED = 'state_rejected'
NetworkCommand.STATE_CANCELLED = 'state_cancelled'

--== Event Constants

NetworkCommand.EVENT = 'network-command-event'

NetworkCommand.STATE_UPDATED = 'state-updated'
NetworkCommand.PRIORITY_UPDATED = 'priority-updated'


--======================================================--
-- Start: Setup DMC Objects

-- __init__()
--
-- @param params table
--   type: one of the TYPE_* constants
--   priority: one of HIGH, MEDIUM, LOW, default MEDIUM
--   timeout: number, seconds before the call fails, optional
--   order: number, its place in line among commands of one priority
--   command: table, the network.* arguments (url, method, listener,
--     params, filename, basedir, contenttype)
--
function NetworkCommand:__init__( params )
	--print( "NetworkCommand:__init__ ", params )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	--== Create Properties ==--

	self._type = params.type
	self._state = self.STATE_PENDING
	self._priority = params.priority or self.MEDIUM
	self._order = params.order or 0

	self._timeout = params.timeout -- seconds, or nil
	self._timeout_timer = nil

	self._command = params.command or {}

	self._net_id = nil -- id from network.* call, can use to cancel
	self._network = nil -- network object to use, set on execute()

end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function NetworkCommand.__getters:key()
	--print( "NetworkCommand.__getters:key" )
	return tostring( self )
end


-- getter, command type
--
function NetworkCommand.__getters:type()
	--print( "NetworkCommand.__getters:type" )
	return self._type
end


-- getter, place in line among commands of the same priority
--
function NetworkCommand.__getters:order()
	return self._order
end


-- getter/setter, command priority
--
function NetworkCommand.__getters:priority()
	--print( "NetworkCommand.__getters:priority" )
	return self._priority
end
function NetworkCommand.__setters:priority( value )
	--print( "NetworkCommand.__setters:priority ", value )
	assert( value==self.HIGH or value==self.MEDIUM or value==self.LOW, "NetworkCommand.priority: expected HIGH, MEDIUM or LOW" )
	if self._priority == value then return end
	self._priority = value
	if self:_isDone() then return end
	self:dispatchEvent( NetworkCommand.PRIORITY_UPDATED )
end


-- getter/setter, command state
--
function NetworkCommand.__getters:state()
	--print( "NetworkCommand.__getters:state" )
	return self._state
end
function NetworkCommand.__setters:state( value )
	--print( "NetworkCommand.__setters:state ", value )
	if self._state == value then return end
	self._state = value
	self:dispatchEvent( NetworkCommand.STATE_UPDATED )
end


-- isDone()
-- true once resolved, rejected or cancelled
--
function NetworkCommand:isDone()
	return self:_isDone()
end


-- execute()
-- start the network call
--
-- @param _network the network.* API to call
--
function NetworkCommand:execute( _network )
	--print( "NetworkCommand:execute" )
	assert( _network, "NetworkCommand:execute requires a network object" )
	assert( self._state==self.STATE_PENDING, "NetworkCommand:execute: already executed" )
	--==--
	local t = self._type
	local p = self._command

	self._network = _network

	-- Setup basic Corona network.* callback

	local callback = function( event )
		-- the first answer wins: the network's, or the timeout's
		if self._state ~= self.STATE_UNFULFILLED then return end
		-- a progress event, download or upload
		if event.phase and event.phase~='ended' then
			if p.listener then
				event.requestId = self
				p.listener( event )
			end
			return
		end

		self:_stopTimer()
		self._net_id = nil

		-- the caller's listener runs before the next command starts;
		-- an error in it still moves the queue on
		local ok, err = true, nil
		if p.listener then
			event.requestId = self
			ok, err = xpcall( function() p.listener( event ) end, debug.traceback )
		end

		-- set Command Object next state
		if event.isError then
			self.state = self.STATE_REJECTED
		else
			self.state = self.STATE_RESOLVED
		end

		if not ok then error( err, 0 ) end
	end

	-- Set Command Object active state and
	-- call appropriate Corona network.* function

	self.state = self.STATE_UNFULFILLED

	self:_startTimer( callback )

	if t == self.TYPE_REQUEST then
		self._net_id = _network.request( p.url, p.method, callback, p.params )

	elseif t == self.TYPE_DOWNLOAD then
		self._net_id = _network.download( p.url, p.method, callback, p.params, p.filename, p.basedir )

	elseif t == self.TYPE_UPLOAD then
		self._net_id = _network.upload( p.url, p.method, callback, p.params, p.filename, p.basedir, p.contenttype )

	end

end


-- cancel()
-- cancel the network call, pending or active; its listener isn't
-- called, as with network.cancel()
--
-- @return true if cancelled, false if already done
--
function NetworkCommand:cancel()
	--print( "NetworkCommand:cancel" )
	if self:_isDone() then return false end

	self:_stopTimer()
	self:_cancelNetworkCall()
	self.state = self.STATE_CANCELLED
	return true
end



--====================================================================--
--== Private Methods


function NetworkCommand:_isDone()
	local s = self._state
	return s==self.STATE_RESOLVED or s==self.STATE_REJECTED or s==self.STATE_CANCELLED
end


function NetworkCommand:_cancelNetworkCall()
	local net, id = self._network, self._net_id
	self._net_id = nil
	if net and id~=nil and net.cancel then net.cancel( id ) end
end


-- _startTimer()
-- the timeout: a failed call if the network hasn't answered in time
--
function NetworkCommand:_startTimer( callback )
	-- print( "NetworkCommand:_startTimer" )
	if not self._timeout or self._timeout <= 0 then return end

	self:_stopTimer()

	self._timeout_timer = timer.performWithDelay( self._timeout*1000, function()
		self._timeout_timer = nil
		if self._state ~= self.STATE_UNFULFILLED then return end
		self:_cancelNetworkCall()
		-- like the event of a failed network call
		callback( {
			name='networkRequest',
			phase='ended',
			isError=true,
			status=-1,
			url=self._command.url,
			response=nil,
			responseHeaders={},
			bytesTransferred=0,
			timedOut=true
		} )
	end )

end

function NetworkCommand:_stopTimer()
	-- print( "NetworkCommand:_stopTimer" )
	if self._timeout_timer == nil then return end
	timer.cancel( self._timeout_timer )
	self._timeout_timer = nil
end




--====================================================================--
--== Nice Network Base Class
--====================================================================--


local NiceNetwork = newClass( ObjectBase, {name="Nice Network"} )

NiceNetwork.VERSION = VERSION

--== Class Constants

-- priority constants
NiceNetwork.HIGH = NetworkCommand.HIGH
NiceNetwork.MEDIUM = NetworkCommand.MEDIUM
NiceNetwork.LOW = NetworkCommand.LOW

NiceNetwork.DEFAULT_ACTIVE_QUEUE_LIMIT = 2
NiceNetwork.MIN_ACTIVE_QUEUE_LIMIT = 1

NiceNetwork.NetworkCommand = NetworkCommand

--== Event Constants

NiceNetwork.EVENT = 'nicenet-event'

NiceNetwork.QUEUE_UPDATE = 'queue-updated-event'


--======================================================--
-- Start: Setup DMC Objects

-- __init__()
--
-- @param params table, optional
--   network: the network.* API to use, default the global network
--   active_queue_limit: number, calls at once, default 2
--   default_priority: priority of a new command, default MEDIUM
--   debug_on: boolean, print each call, default from the cfg
--
function NiceNetwork:__init__( params )
	--print( "NiceNetwork:__init__" )
	params = params or {}
	self:superCall( '__init__', params )
	--==--

	if params.debug_on==nil then params.debug_on = Config.debug_active end

	--== Create Properties ==--

	self._default_priority = params.default_priority or NiceNetwork.MEDIUM
	self._active_limit = self.DEFAULT_ACTIVE_QUEUE_LIMIT
	if params.active_queue_limit then
		self:_checkLimit( params.active_queue_limit )
		self._active_limit = params.active_queue_limit
	end
	self._debug_on = params.debug_on

	-- dict of Active Command Objects, keyed on object
	self._active_queue = nil

	-- dict of Pending Command Objects, keyed on object
	self._pending_queue = nil

	self._order = 0 -- count of commands, for first-in first-out
	self._processing = false
	self._process_again = false

	-- save network object, param or global
	self._network = params.network or _G.network
	self._netCmd_f = nil -- callback for network command objects
end


-- __initComplete__()
--
function NiceNetwork:__initComplete__()
	--print( "NiceNetwork:__initComplete__" )
	self:superCall( '__initComplete__' )
	--==--
	-- create data structure
	self._active_queue = {}
	self._pending_queue = {}

	self._netCmd_f = self:createCallback( self._networkCommandEvent_handler )

	-- the network.* API, called with a dot like the module
	self.request = self:createCallback( self._request )
	self.download = self:createCallback( self._download )
	self.upload = self:createCallback( self._upload )
	self.cancel = self:createCallback( self._cancel )
end

function NiceNetwork:__undoInitComplete__()
	--print( "NiceNetwork:__undoInitComplete__" )
	-- cancel every call, pending first so none starts
	for _, queue in ipairs( { self._pending_queue, self._active_queue } ) do
		local cmds = {}
		for cmd in pairs( queue ) do tinsert( cmds, cmd ) end
		for _, cmd in ipairs( cmds ) do
			cmd:removeEventListener( cmd.EVENT, self._netCmd_f )
			cmd:cancel()
		end
	end
	self._netCmd_f=nil
	-- remove data structure
	self._active_queue = nil
	self._pending_queue = nil
	--==--
	self:superCall( '__undoInitComplete__' )
end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Static Functions


-- makeGlobal()
-- route the global network's request(), download(), upload() and
-- cancel() through the module's NiceNetwork, by replacing them in the
-- network table itself: code holding a reference to it, from before
-- the call, goes through the queue too. Other network.* functions are
-- left alone
--
-- @return the module's NiceNetwork
--
function NiceNetwork.makeGlobal()
	local nn = NiceNetwork._instance
	if Global then return nn end
	local net = _G.network
	assert( net, "NiceNetwork.makeGlobal: no global network" )

	local g = { network=net }
	for _, name in ipairs( GLOBAL_CALLS ) do
		g[ name ] = net[ name ]
		net[ name ] = nn[ name ]
	end
	Global = g
	return nn
end


-- restoreGlobal()
-- put the global network's own calls back; the module's NiceNetwork
-- keeps working through its queue
--
-- @return the module's NiceNetwork, or nil if it wasn't global
--
function NiceNetwork.restoreGlobal()
	if not Global then return nil end
	local g = Global
	Global = nil
	for _, name in ipairs( GLOBAL_CALLS ) do
		g.network[ name ] = g[ name ]
	end
	return NiceNetwork._instance
end


-- the calls to make for a network: once makeGlobal() has replaced
-- the global network's, its own, so a NiceNetwork on it doesn't
-- call itself
--
function NiceNetwork._networkCalls( net )
	if Global and net==Global.network then return Global end
	return net
end



--====================================================================--
--== Public Methods


function NiceNetwork.__setters:network( value )
	-- print( "NiceNetwork.__setters:network ", value )
	assert( value, "NiceNetwork.network: expected the network.* API" )
	self._network = value
end
function NiceNetwork.__getters:network()
	-- print( "NiceNetwork.__getters:network " )
	return self._network
end


function NiceNetwork.__getters:active_queue_limit()
	return self._active_limit
end
function NiceNetwork.__setters:active_queue_limit( value )
	self:_checkLimit( value )
	self._active_limit = value
	self:_processQueue()
end


function NiceNetwork.__getters:default_priority()
	return self._default_priority
end
function NiceNetwork.__setters:default_priority( value )
	assert( value==self.HIGH or value==self.MEDIUM or value==self.LOW, "NiceNetwork.default_priority: expected HIGH, MEDIUM or LOW" )
	self._default_priority = value
end


-- _request()
-- this is a replacement for Corona network.request(), as nicenet.request()
--[[
network.request( url, method, listener [, params] )
--]]
-- @return the NetworkCommand, also event.requestId in the listener
--
function NiceNetwork:_request( url, method, listener, params )
	-- print( "NiceNetwork:_request ", url, method )

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
		timeout=params and params.timeout,
		priority=params and params.priority
	}

	return self:_insertCommandIntoQueue( cmd_params )
end


-- _download()
-- this is a replacement for Corona network.download(), as nicenet.download()
--[[
network.download( url, method, listener [, params], filename [, baseDirectory] )
--]]
function NiceNetwork:_download( url, method, listener, params, filename, basedir )
	--print( "NiceNetwork:_download ", url, filename )

	--== Process optional parameters

	-- network params
	if params~=nil and type(params) ~= 'table' then
		params, filename, basedir = nil, params, filename
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
		timeout=params and params.timeout,
		priority=params and params.priority
	}

	return self:_insertCommandIntoQueue( cmd_params )
end


-- _upload()
-- this is a replacement for Corona network.upload(), as nicenet.upload()
--[[
network.upload( url, method, listener [, params], filename [, baseDirectory] [, contentType] )
--]]
function NiceNetwork:_upload( url, method, listener, params, filename, basedir, contenttype )

	--== Process optional parameters

	-- network params
	if params~=nil and type(params) ~= 'table' then
		params, filename, basedir, contenttype = nil, params, filename, basedir
	end

	-- base directory, skipped when the content type follows the file name
	if type(basedir) == 'string' then
		basedir, contenttype = nil, basedir
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
		type=NetworkCommand.TYPE_UPLOAD,
		timeout=params and params.timeout,
		priority=params and params.priority
	}

	return self:_insertCommandIntoQueue( cmd_params )
end


-- _cancel()
-- this is a replacement for Corona network.cancel(), as nicenet.cancel()
--
-- @param command a NetworkCommand from request(), download() or
--   upload(); anything else is passed on to network.cancel()
--
function NiceNetwork:_cancel( command )
	-- print( "NiceNetwork:_cancel ", command )
	if type( command )=='table' and command.isa and command:isa( NetworkCommand ) then
		return command:cancel()
	end
	local net = NiceNetwork._networkCalls( self._network )
	if command~=nil and net and net.cancel then
		return net.cancel( command )
	end
	return false
end



--====================================================================--
--== Private Methods


function NiceNetwork:_debug( ... )
	if not self._debug_on then return end
	local args = { ... }
	for i = 1, #args do args[i] = tostring( args[i] ) end
	print( "NiceNet: "..table.concat( args, " " ) )
end


function NiceNetwork:_checkLimit( value )
	assert( type( value )=='number' and value >= self.MIN_ACTIVE_QUEUE_LIMIT,
		"NiceNetwork: active_queue_limit must be a number, "..self.MIN_ACTIVE_QUEUE_LIMIT.." or more" )
end


function NiceNetwork:_insertCommandIntoQueue( params )
	--print( "NiceNetwork:_insertCommandIntoQueue ", params.type )

	self._order = self._order + 1
	params.order = self._order
	if params.priority==nil then params.priority = self._default_priority end
	assert( params.priority==NetworkCommand.HIGH or params.priority==NetworkCommand.MEDIUM or params.priority==NetworkCommand.LOW,
		"NiceNetwork: params.priority must be HIGH, MEDIUM or LOW" )

	local net_command = NetworkCommand:new( params )
	net_command:addEventListener( net_command.EVENT, self._netCmd_f )
	self._pending_queue[ net_command ] = net_command
	self:_debug( "queued", net_command.type, params.command.method, params.command.url )

	self:_processQueue()

	return net_command
end

function NiceNetwork:_removeCommandFromQueue( net_command )
	--print( "NiceNetwork:_removeCommandFromQueue ", net_command.type )

	self._active_queue[ net_command ] = nil
	self._pending_queue[ net_command ] = nil
	net_command:removeEventListener( net_command.EVENT, self._netCmd_f )
	self:_debug( "done", net_command.type, net_command.state )

	self:_processQueue()
end


-- _nextCommand()
-- the pending command of highest priority, first in first out
--
function NiceNetwork:_nextCommand()
	local next_cmd
	for cmd in pairs( self._pending_queue ) do
		if not next_cmd or cmd.priority < next_cmd.priority
			or ( cmd.priority == next_cmd.priority and cmd.order < next_cmd.order ) then
			next_cmd = cmd
		end
	end
	return next_cmd
end


function NiceNetwork:_processQueue()
	--print( "NiceNetwork:_processQueue" )
	if not self._active_queue then return end -- removed

	-- a command may finish while it starts: go round again then
	if self._processing then
		self._process_again = true
		return
	end
	self._processing = true

	local first_err
	repeat
		self._process_again = false
		while self._active_queue and Utils.tableSize( self._active_queue ) < self._active_limit do
			-- we have slots left, checking for pending commands
			local next_cmd = self:_nextCommand()
			if next_cmd == nil then break end

			self._active_queue[ next_cmd ] = next_cmd
			self._pending_queue[ next_cmd ] = nil
			self:_debug( "starting", next_cmd.type, next_cmd._command.method, next_cmd._command.url )
			local ok, err = xpcall( function() next_cmd:execute( NiceNetwork._networkCalls( self._network ) ) end, debug.traceback )
			if not ok then
				-- a network.* call raised (bad arguments): the command
				-- fails, the queue moves on, the error is raised after
				first_err = first_err or err
				next_cmd:_stopTimer()
				next_cmd._net_id = nil
				next_cmd.state = next_cmd.STATE_REJECTED
			end
		end
	until not self._process_again or not self._active_queue

	self._processing = false

	if self._active_queue then self:_broadcastStatus() end
	if first_err then error( first_err, 0 ) end
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
		tinsert( status[ cmd.priority ], cmd )
	end
	for _, list in pairs( status ) do
		table.sort( list, function( a, b ) return a.order < b.order end )
	end

	return status
end


-- _broadcastStatus()
-- count status, and send event
--
function NiceNetwork:_broadcastStatus()
	--print( "NiceNetwork:_broadcastStatus" )
	local data = {
		active = self:_checkStatus( self._active_queue ),
		pending = self:_checkStatus( self._pending_queue )
	}
	self:dispatchEvent( self.QUEUE_UPDATE, data )
end



--====================================================================--
--== Event Handlers


-- _networkCommandEvent_handler()
-- handle any events from Network Command objects
--
function NiceNetwork:_networkCommandEvent_handler( event )
	--print( "NiceNetwork:_networkCommandEvent_handler ", event.type )
	local cmd = event.target

	if event.type == cmd.PRIORITY_UPDATED then
		self:_broadcastStatus()

	elseif event.type == cmd.STATE_UPDATED then
		if cmd:isDone() then
			-- remove from the queues, start the next
			self:_removeCommandFromQueue( cmd )
		end

	end
end




--====================================================================--
--== The Module: One NiceNetwork


-- like Corona's network, the module is ready to use; the class is
-- nicenet.NiceNetwork, for a queue of its own
local nicenet = NiceNetwork:new()
nicenet.NiceNetwork = NiceNetwork
NiceNetwork._instance = nicenet

if Config.make_global and _G.network then
	NiceNetwork.makeGlobal()
end



return nicenet

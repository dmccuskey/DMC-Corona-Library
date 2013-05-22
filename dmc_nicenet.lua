--====================================================================--
-- dmc_nicenet.lua
--
--
-- by David McCuskey
-- Documentation:
--====================================================================--

--[[

Copyright (C) 2013 David McCuskey. All Rights Reserved.

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

local VERSION = "0.9.0"


--====================================================================--
-- Imports
--====================================================================--

local Objects = require( "dmc_objects" )
local Utils = require( "dmc_utils" )



--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase


--====================================================================--
-- Support Methods
--====================================================================--



--====================================================================--
-- Network Command Class
--====================================================================--

local NetworkCommand = inheritsFrom( CoronaBase )
NetworkCommand.NAME = "Network Command"


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


--== Event Constants
NetworkCommand.EVENT = "network_command_event"
NetworkCommand.UPDATED = "network_command_updated_event"

NetworkCommand.STATE_UPDATED = "state_updated"
NetworkCommand.PRIORITY_UPDATED = "priority_updated"



function NetworkCommand:_init( params )
	--print( "NetworkCommand:_init ", params )
	self:superCall( "_init" )
	--==--

	params = params or {}

	--== Create Properties ==--

	self._params = params
	self._type = params.type
	self._state = self.STATE_PENDING
	self._priority = params.priority or self.MEDIUM

	self._command = params.command
	-- url
	-- method
	-- listener
	-- params


	--== Display Groups ==--

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


function NetworkCommand.__getters:key()
	--print( "NetworkCommand.__getters:priority" )
	return tostring( self )
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

-- getter/setter, command type
--
function NetworkCommand.__getters:type()
	--print( "NetworkCommand.__getters:type" )
	return self._type
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
-- start the netowrk process
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
		network.request( p.url, p.method, callback, p.params )

	elseif t == self.TYPE_DOWNLOAD then
		network.download( p.url, p.method, callback, p.params, p.filename, p.basedir )

	elseif t == self.TYPE_UPLOAD then
		network.upload( p.url, p.method, callback, p.params, p.filename, p.basedir,  p.contenttype )

	end

end



--== Private Methods


--== Event Methods



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



--== Start: Setup DMC Objects


function NiceNetwork:_init( params )
	--print( "NiceNetwork:_init" )
	self:superCall( "_init" )
	--==--

	params = params or {}

	--== Create Properties ==--

	self._params = params
	self._default_priority = params.default_priority or NetworkCommand.MEDIUM 

	self._active_limit = self.DEFAULT_ACTIVE_QUEUE_LIMIT

	self._active_queue = nil -- dict of active commands, keyed on object raw id
	self._pending_queue = nil -- dict of active commands, keyed on object raw id

	--== Display Groups ==--

	--== Object References ==--

end


-- _initComplete()
--
function NiceNetwork:_initComplete()
	--print( "NiceNetwork:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	self._active_queue = {}
	self._pending_queue = {}

end

function NiceNetwork:_undoInitComplete()
	--print( "NiceNetwork:_undoInitComplete" )

	self._active_queue = nil
	self._pending_queue = nil

	--==--
	self:superCall( "_undoInitComplete" )
end


--== END: Setup DMC Objects


--== Public Methods



function NiceNetwork:request( url, method, listener, params )
	--print( "NiceNetwork:request ", url, method )
	local command, p, o 

	-- save network parameters
	command = {
		url=url,
		method=method,
		listener=listener,
		params=params
	}
	-- save command params
	p = {
		command=command,
		type=NetworkCommand.TYPE_REQUEST,
		priority=self._default_priority
	}

	return self:_insertCommand( p )
end


function NiceNetwork:download( url, method, listener, params, filename, basedir )
	--print( "NiceNetwork:download ", url, filename )
	local command, p, o 

	-- save network parameters
	command = {
		url=url,
		method=method,
		listener=listener,
		params=params,
		filename=filename,
		basedir=basedir
	}
	-- save command params
	p = {
		command=command,
		type=NetworkCommand.TYPE_DOWNLOAD,
		priority=self._default_priority
	}

	return self:_insertCommand( p )
end





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


--== Event Methods



function NiceNetwork:network_command_event( event )
	--print( "NiceNetwork:network_command_event ", event.type )
	local cmd = event.target

	if event.type == cmd.PRIORITY_UPDATED then
		-- count status, and send event
		self:_broadcastStatus()

	elseif event.type == cmd.STATE_UPDATED then

		if cmd.state == cmd.STATE_REJECTED or cmd.state == cmd.STATE_RESOLVED then
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



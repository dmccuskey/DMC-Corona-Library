--====================================================================--
-- dmc_wamp.serializer
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_wamp.lua
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

--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"


--====================================================================--
-- Imports

local json = require 'json'

local Objects = require 'lua_objects'
local Utils = require 'lua_utils'

local MessageFactory = require 'dmc_wamp.messages'


--====================================================================--
-- Setup, Constants

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local ObjectBase = Objects.ObjectBase



--====================================================================--
-- Serializer Class
--====================================================================--

local Serializer = inheritsFrom( ObjectBase )
Serializer.NAME = "Serializer Class"

function Serializer:_init( params )
	-- print( "Serializer:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--

	if not self.is_intermediate and not params.serializer then
		error( "Serializer: requires parameter 'serializer'" )
	end

	self._serializer = params.serializer

end

-- @params msg Message Object
--
-- Implements :func:`autobahn.wamp.interfaces.ISerializer.serialize`
--
function Serializer:serialize( msg )
	-- print( "Serializer:serialize", msg.TYPE )
	return msg:serialize( self._serializer ), self._serializer.BINARY
end

-- Implements :func:`autobahn.wamp.interfaces.ISerializer.unserialize`
--
function Serializer:unserialize( payload )
	-- print( "Serializer:unserialize", payload )

	local raw_msg, msg_class, msg

	raw_msg = self._serializer:unserialize( payload )
	msg_class = MessageFactory.map[ raw_msg[1] ]

	if not msg_class then
		error( "missing msg class, msg: " .. tostring( payload ) )
	else
		msg = msg_class.parse( raw_msg )
	end

	return msg
end



--====================================================================--
-- JSON Serializer
--====================================================================--

local JsonSerializer = inheritsFrom( Serializer )
JsonSerializer.NAME = "Json Serializer Class"

JsonSerializer.SERIALIZER_ID = "json"



--====================================================================--
-- JSON Object Serializer
--====================================================================--

local JsonObjSerializer = inheritsFrom( ObjectBase )
JsonObjSerializer.NAME = "Json Object Serializer Class"

JsonObjSerializer.BINARY = false

-- Implements :func:`autobahn.wamp.interfaces.IObjectSerializer.serialize`
--
function JsonObjSerializer:serialize( msg )
	-- print( "JsonObjSerializer:serialize", msg )
	local encoded_json = json.encode( msg )
	encoded_json = Utils.decodeLuaTable( encoded_json )
	encoded_json = Utils.decodeLuaInteger( encoded_json )
	return encoded_json
end

-- Implements :func:`autobahn.wamp.interfaces.IObjectSerializer.unserialize`
--
function JsonObjSerializer:unserialize( payload )
	-- print( "JsonObjSerializer:unserialize", payload )
	return json.decode( payload )
end




--====================================================================--
-- Serializer Factory
--====================================================================--

local SerializerFactory = {}


function SerializerFactory.create( s_type, params )
	-- print( "SerializerFactory.create", s_type )
	params = params or {}
	--==--

	local o

	if s_type == JsonSerializer.SERIALIZER_ID then
		params.serializer=JsonObjSerializer:new()
		o = JsonSerializer:new( params )

	else
		error( "ERROR, serializer factory" )
	end

	return o
end


return SerializerFactory

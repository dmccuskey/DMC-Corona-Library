--====================================================================--
-- dmc_corona/dmc_wamp/serializer.lua
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
--== DMC Corona Library : DMC WAMP Serializer
--====================================================================--


--[[
WAMP support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Imports


local json = require 'json'

local Objects = require 'lib.dmc_lua.lua_objects'

local WMessageFactory = require 'dmc_wamp.message'
local WUtils = require 'dmc_wamp.utils'



--====================================================================--
--== Setup, Constants


-- setup some aliases to make code cleaner
local newClass = Objects.newClass

local LOCAL_DEBUG = false



--====================================================================--
--== Serializer Class
--====================================================================--


local Serializer = newClass( nil, { name="Serializer" } )

function Serializer:__new__( params )
	-- print( "Serializer:__init__" )
	params = params or {}
	self:superCall( '__new__', params )
	--==--

	if self.is_class then return end

	assert( params.serializer, "Serializer: requires parameter 'serializer'" )

	self._serializer = params.serializer

end

-- @params msg Message Object
--
-- Implements :func:`autobahn.wamp.interfaces.ISerializer.serialize`
--
function Serializer:serialize( msg )
	-- print( "Serializer:serialize", msg.MESSAGE_TYPE )
	local payload = msg:serialize( self._serializer )
	if LOCAL_DEBUG then print( payload ) end
	return payload, self._serializer.BINARY
end

-- Implements :func:`autobahn.wamp.interfaces.ISerializer.unserialize`
--
function Serializer:unserialize( payload )
	-- print( "Serializer:unserialize", payload )

	local raw_msg, msg_class, msg

	raw_msg = self._serializer:unserialize( payload )
	msg_class = WMessageFactory.map[ raw_msg[1] ]

	if not msg_class then
		error( "missing msg class, msg: " .. tostring( payload ) )
	else
		msg = msg_class.parse( raw_msg )
	end

	return msg
end



--====================================================================--
--== JSON Serializer
--====================================================================--


local JsonSerializer = newClass( Serializer, { name="JSON Serializer Class" } )

JsonSerializer.SERIALIZER_ID = "json"



--====================================================================--
--== JSON Object Serializer
--====================================================================--


local JsonObjSerializer = newClass( ObjectBase, { name="JSON Object Serializer" } )

JsonObjSerializer.BINARY = false

-- Implements :func:`autobahn.wamp.interfaces.IObjectSerializer.serialize`
--
function JsonObjSerializer:serialize( msg )
	-- print( "JsonObjSerializer:serialize", msg )
	local encoded_json = json.encode( msg )
	encoded_json = WUtils.decodeLuaTable( encoded_json )
	encoded_json = WUtils.decodeLuaInteger( encoded_json )
	return encoded_json
end

-- Implements :func:`autobahn.wamp.interfaces.IObjectSerializer.unserialize`
--
function JsonObjSerializer:unserialize( payload )
	-- print( "JsonObjSerializer:unserialize", payload )
	return json.decode( payload )
end




--====================================================================--
--== Serializer Factory
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

--====================================================================--
-- dmc_corona/dmc_sockets/ssl_params.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014-2015 David McCuskey. All Rights Reserved.

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
--== DMC Lua Library : Sockets SSL Params
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.2.0"



--====================================================================--
--== Imports


local Objects = require 'lib.dmc_lua.lua_objects'
local Utils = require 'lib.dmc_lua.lua_utils'


-- Check imports
-- TODO: work on this
assert( Objects, "lua_error: requires lua_objects" )
if checkModule then checkModule( Objects, '1.1.2' ) end



--====================================================================--
--== Setup, Constants


-- none



--====================================================================--
--== SSL Params Class
--====================================================================--


local SSLParams = newClass( nil, { name="SSL Params" } )

--== Class Constants ==--

SSLParams.__version = VERSION

-- Modes
SSLParams.CLIENT = 'client'
SSLParams.MODES = {
	SSLParams.CLIENT,
}

-- secure protocols
SSLParams.TLS_V1 = 'tlsv1'
SSLParams.SSL_V3 = 'sslv3'

SSLParams.PROTOCOLS = {
	SSLParams.TLS_V1,
	SSLParams.SSL_V3
}

-- options
SSLParams.ALL = 'all'

SSLParams.OPTIONS = {
	SSLParams.ALL
}

-- verify options
SSLParams.NONE = 'none'
SSLParams.PEER = 'peer'

SSLParams.VERIFY_OPTS = {
	SSLParams.NONE,
	SSLParams.PEER
}



function SSLParams:__new__( params )
	-- print( "SSLParams:__new__", params )
	params = params or {}
	--==--

	if self.is_class then return end

	assert( type(params)=='table', "SSLParams: incorrect parameter type" )

	-- save args
	self._mode = self.CLIENT
	self._options = self.ALL
	self._protocol = self.TLS_V1
	self._verify = self.NONE

	if params then self:update( params ) end
end


function SSLParams.__setters:mode( value )
	-- print( "SSLParams.__setters:mode", value )
	assert( Utils.propertyIn( self.MODES, value ), "unknown mode" )
	--==--
	self._mode = value
end
function SSLParams.__getters:mode( )
	-- print( "SSLParams.__getters:mode" )
	return self._mode
end

function SSLParams.__setters:options( value )
	-- print( "SSLParams.__setters:options", value )
	assert( Utils.propertyIn( self.OPTIONS, value ), "unknown option" )
	--==--
	self._options = value
end
function SSLParams.__getters:options( )
	-- print( "SSLParams.__getters:options" )
	return self._options
end

function SSLParams.__setters:protocol( value )
	-- print( "SSLParams.__setters:protocol", value )
	assert( Utils.propertyIn( self.PROTOCOLS, value ), "unknown protocol" )
	--==--
	self._protocol = value
end
function SSLParams.__getters:protocol( )
	-- print( "SSLParams.__getters:protocol" )
	return self._protocol
end

function SSLParams.__setters:verify( value )
	-- print( "SSLParams.__setters:verify", value )
	assert( Utils.propertyIn( self.VERIFY_OPTS, value ), "unknown verify" )
	--==--
	self._verify = value
end
function SSLParams.__getters:verify( )
	-- print( "SSLParams.__getters:verify" )
	return self._verify
end



function SSLParams:update( options )
	-- print( "SSLParams:update", options )
	assert( type(options)=='table', "bad value for update" )
	--==--
	if options.mode then self.mode = options.mode end
	if options.options then self.options = options.options end
	if options.protocol then self.protocol = options.protocol end
	if options.verify then self.verify = options.verify end
end




return SSLParams

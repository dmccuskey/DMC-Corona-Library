--====================================================================--
-- dmc_wamp/auth.lua
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
--== DMC Corona Library : DMC WAMP Auth
--====================================================================--


--[[
Wamp support adapted from:
* AutobahnPython (https://github.com/tavendo/AutobahnPython/)
--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
--== Imports


local crypto = require 'crypto'
local mime = require 'mime'
local mbase64_encode = mime.b64



--====================================================================--
--== Setup, Constants


-- The characters from which :func:`autobahn.wamp.auth.generate_wcs`
-- generates secrets
local WCS_SECRET_CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"



--====================================================================--
--== Support Functions


local function generate_totp_secret( length )
	-- print( "dmc_wamp.auth.generate_totp_secret ", length )
	--==--
	length = length or 10

	assert( type( length ) == 'number' )

	error( "not implemented" )
end


local function compute_totp( secret, offset )
	-- print( "dmc_wamp.auth.compute_totp ", secret, offset )
	--==--
	offset = offset or 0

	assert( type( secret ) == 'string' )
	assert( type( length ) == 'number' )

	error( "not implemented" )
end



local function pbkdf2( params )
	-- print( "dmc_wamp.auth.pbkdf2 ", params )
	params = params or {}
	--==--
	local data, salt = params.data, params.salt
	local iterations = params.iterations or 1000
	local keylen = params.keylen or 32
	local hashfunc = params.hashfunc or crypto.sha256

	assert( type( data ) == 'string' )
	assert( type( salt ) == 'string' )
	assert( type( iterations ) == 'number' )
	assert( type( keylen ) == 'number' )
	assert( type( hashfunc ) == 'function' )

	-- return _pdkdf2( data, salt, iterations, keylen, hashfunc )
	error( "not implemented" )

end



local function derive_key( params )
	-- print( "dmc_wamp.auth.derive_key ", params )
	params = params or {}
	--==--
	local secret, salt = params.secret, params.salt
	local iterations = params.iterations or 1000
	local keylen = params.keylen or 32

	assert( type( secret ) == 'string' )
	assert( type( salt ) == 'string' )
	assert( type( iterations ) == 'number' )
	assert( type( keylen ) == 'number' )

	error( "not implemented" )
end



local function generate_wcs( length )
	-- print( "dmc_wamp.auth.generate_wcs ", length )
	--==--
	length = length or 10

	assert( type( length ) == 'number' )

	error( "not implemented" )
end



local function compute_wcs( key, challenge )
	-- print( "dmc_wamp.auth.compute_wcs ", key, challenge )
	--==--
	assert( type( key ) == 'string' )
	assert( type( challenge ) == 'string' )

	local sig = crypto.hmac( crypto.sha256, challenge, key, true )
	return mbase64_encode( sig )
end




--====================================================================--
--== Auth Exports
--====================================================================--


return {
	generate_totp_secret=generate_totp_secret,
	compute_totp=compute_totp,
	pbkdf2=pbkdf2,
	derive_key=derive_key,
	generate_wcs=generate_wcs,
	compute_wcs=compute_wcs
}


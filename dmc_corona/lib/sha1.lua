--====================================================================--
-- dmc_corona/lib/sha1.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-websockets
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2026 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : SHA-1
--====================================================================--


--[[

The SHA-1 hash (FIPS 180-4, RFC 3174) in Lua 5.1, written from the
standard. The WebSocket handshake uses it to check the server's
Sec-WebSocket-Accept header (RFC 6455, section 4.2.2).

	local SHA1 = require 'lib.sha1'
	SHA1.sha1( 'abc' )         -- 'a9993e364706816aba3e25717850c26c9cd0d89d'
	SHA1.sha1_binary( 'abc' )  -- the same 20 bytes, as a string

SHA-1 is no longer safe where an attacker gains from a collision, such
as signatures. The handshake doesn't depend on that.

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.0.0"



--====================================================================--
--== Imports


local bit = require 'lib.dmc_lua.bit'



--====================================================================--
--== Setup, Constants


local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local lshift = bit.lshift
local rshift = bit.rshift

local mfloor = math.floor
local sbyte = string.byte
local schar = string.char
local sformat = string.format
local srep = string.rep
local tconcat = table.concat

local MOD = 2^32 -- words are 32 bits, sums wrap



--====================================================================--
--== Support Functions


-- rotate a 32-bit word left by n bits
--
local function rotate( x, n )
	return bor( lshift( x, n ), rshift( x, 32 - n ) )
end

-- a number as 4 bytes, most significant first
--
local function word( n )
	n = n % MOD
	return schar(
		mfloor( n / 0x1000000 ) % 0x100,
		mfloor( n / 0x10000 ) % 0x100,
		mfloor( n / 0x100 ) % 0x100,
		n % 0x100
	)
end

-- the message, then a 1 bit, zeros up to 8 bytes short of a whole
-- 64-byte block, then the message's length in bits as 8 bytes
--
local function pad( msg )
	local len = #msg
	local zeros = ( 55 - len ) % 64
	local bits = len * 8
	return msg .. '\128' .. srep( '\0', zeros )
		.. word( mfloor( bits / MOD ) ) .. word( bits )
end



--====================================================================--
--== SHA-1 Facade
--====================================================================--


local M = {}

M.VERSION = VERSION


-- the hash of a string, as a string of 20 bytes
--
function M.sha1_binary( msg )
	assert( type( msg ) == 'string', "sha1: expected a string" )

	local h0, h1, h2, h3, h4 = 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0

	msg = pad( msg )

	local w = {}
	for pos = 1, #msg, 64 do

		for i = 0, 15 do
			local b1, b2, b3, b4 = sbyte( msg, pos + i * 4, pos + i * 4 + 3 )
			w[i] = b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4
		end
		for i = 16, 79 do
			w[i] = rotate( bxor( w[i-3], w[i-8], w[i-14], w[i-16] ), 1 )
		end

		local a, b, c, d, e = h0, h1, h2, h3, h4

		for i = 0, 79 do
			local f, k
			if i < 20 then
				-- choose: b picks c or d
				f = bxor( d, band( b, bxor( c, d ) ) )
				k = 0x5A827999
			elseif i < 40 then
				f = bxor( b, c, d )
				k = 0x6ED9EBA1
			elseif i < 60 then
				-- majority of b, c, d
				f = bor( band( b, c ), band( d, bor( b, c ) ) )
				k = 0x8F1BBCDC
			else
				f = bxor( b, c, d )
				k = 0xCA62C1D6
			end

			-- bit results may be negative (signed 32 bits): % brings
			-- each term, and the sum, back to 0 .. 2^32-1
			local temp = ( rotate( a, 5 ) % MOD + f % MOD + e + k + w[i] % MOD ) % MOD
			e = d
			d = c
			c = rotate( b, 30 ) % MOD
			b = a
			a = temp
		end

		h0 = ( h0 + a ) % MOD
		h1 = ( h1 + b ) % MOD
		h2 = ( h2 + c ) % MOD
		h3 = ( h3 + d ) % MOD
		h4 = ( h4 + e ) % MOD
	end

	return word( h0 ) .. word( h1 ) .. word( h2 ) .. word( h3 ) .. word( h4 )
end


-- the hash of a string, as 40 hex digits
--
function M.sha1( msg )
	local bytes = { sbyte( M.sha1_binary( msg ), 1, 20 ) }
	for i = 1, 20 do
		bytes[i] = sformat( '%02x', bytes[i] )
	end
	return tconcat( bytes )
end


return M

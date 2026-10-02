--====================================================================--
-- dmc_corona/dmc_websockets/utf8.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-websockets
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
--== DMC Corona Library : DMC WebSockets UTF-8 Validator
--====================================================================--


--[[

Incremental UTF-8 validation (RFC 3629), as required by RFC 6455 for
text messages and close reasons.

Data can be fed in pieces, eg one frame at a time, and a sequence may
be split across pieces. Validation fails as soon as an invalid byte is
seen, so a bad message can be rejected before all of it has arrived.

Rejects overlong encodings, UTF-16 surrogates (U+D800-U+DFFF) and
code points above U+10FFFF.

--]]


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.0.0"



--====================================================================--
--== Setup, Constants


local mmin = math.min
local sbyte = string.byte
local sfind = string.find

-- max values to unpack from string.byte() at once
local CHUNK_SIZE = 2000



--====================================================================--
--== Validator Class
--====================================================================--


local Validator = {}
Validator.__index = Validator


function Validator.new()
	return setmetatable( {
		_need=0, -- continuation bytes still needed for current sequence
		_lo=0x80, -- valid range for the next continuation byte
		_hi=0xBF,
		_valid=true
	}, Validator )
end


-- feed()
-- validate the next piece of data
-- returns false as soon as the data seen so far is invalid
--
function Validator:feed( str )
	if not self._valid then return false end

	local need, lo, hi = self._need, self._lo, self._hi

	-- fast path: not inside a sequence and all ASCII
	if need == 0 and not sfind( str, '[\128-\255]' ) then
		return true
	end

	local len = #str
	for p=1,len,CHUNK_SIZE do
		local bytes = { sbyte( str, p, mmin( p+CHUNK_SIZE-1, len ) ) }
		for i=1,#bytes do
			local b = bytes[i]

			if need == 0 then
				if b < 0x80 then
					-- pass, ASCII
				elseif b >= 0xC2 and b <= 0xDF then
					need, lo, hi = 1, 0x80, 0xBF
				elseif b == 0xE0 then
					need, lo, hi = 2, 0xA0, 0xBF -- no overlongs
				elseif b == 0xED then
					need, lo, hi = 2, 0x80, 0x9F -- no surrogates
				elseif b >= 0xE1 and b <= 0xEF then
					need, lo, hi = 2, 0x80, 0xBF
				elseif b == 0xF0 then
					need, lo, hi = 3, 0x90, 0xBF -- no overlongs
				elseif b >= 0xF1 and b <= 0xF3 then
					need, lo, hi = 3, 0x80, 0xBF
				elseif b == 0xF4 then
					need, lo, hi = 3, 0x80, 0x8F -- max U+10FFFF
				else
					self._valid = false
					return false
				end

			else
				if b < lo or b > hi then
					self._valid = false
					return false
				end
				need, lo, hi = need-1, 0x80, 0xBF
			end
		end
	end

	self._need, self._lo, self._hi = need, lo, hi
	return true
end


-- isComplete()
-- true if data is valid and doesn't end in the middle of a sequence
--
function Validator:isComplete()
	return self._valid and self._need == 0
end



--====================================================================--
--== Support Functions


local function isValid( str )
	local v = Validator.new()
	return v:feed( str ) and v:isComplete()
end



--====================================================================--
--== Module Facade
--====================================================================--


return {
	VERSION = VERSION,
	newValidator = Validator.new,
	isValid = isValid
}

--====================================================================--
-- dmc_lua/lua_objects.lua
--
-- Documentation: http://docs.davidmccuskey.com/
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2011-2015 David McCuskey

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
--== DMC Lua Library : Lua Objects
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.3.0"




--====================================================================--
--== Lua Objects
--====================================================================--


--====================================================================--
--== Imports

local Class = test
local Objects = require 'lua_class'
local EventsMixModule = require 'lua_events_mix'



--====================================================================--
--== Setup, Constants


local Class = Objects.Class
local registerCtorName = Objects.registerCtorName
local registerDtorName = Objects.registerDtorName

local EventsMix = EventsMixModule.EventsMix


-- Add new Dtor name (function references)
registerDtorName( 'removeSelf', Class )



--====================================================================--
--== Object Base Class
--====================================================================--


local ObjectBase = newClass( { Class, EventsMix }, { name="Object Base" } )



--======================================================--
--== Constructor / Destructor


-- __new__()
-- this method drives the construction flow for DMC-style objects
-- typically, you won't override this
--
function ObjectBase:__new__( ... )

	--== Do setup sequence ==--

	self:__init__( ... )

	-- skip these if a Class object (ie, NOT an instance)
	if rawget( self, '__is_class' ) == false then
		self:__initComplete__()
	end

	return self
end


-- __destroy__()
-- this method drives the destruction flow for DMC-style objects
-- typically, you won't override this
--
function ObjectBase:__destroy__()

	--== Do teardown sequence ==--

	-- skip these if a Class object (ie, NOT an instance)
	if rawget( self, '__is_class' ) == false then
		self:__undoInitComplete__()
	end

	self:__undoInit__()
end



--======================================================--
-- Start: Setup Lua Objects

-- __init__
-- initialize the object
--
function ObjectBase:__init__( ... )
	--[[
	there is no __init__ on Class
	-- self:superCall( Class, '__init__', ... )
	--]]
	self:superCall( EventsMix, '__init__', ... )
	--==--
end

-- __undoInit__
-- remove items added during __init__
--
function ObjectBase:__undoInit__()
	self:superCall( EventsMix, '__undoInit__' )
	--[[
	there is no __undoInit__ on Class
	-- self:superCall( Class, '__undoInit__' )
	--]]
end


-- __initComplete__
-- any setup after object is done with __init__
--
function ObjectBase:__initComplete__()
end

-- __undoInitComplete__()
-- remove any items added during __initComplete__
--
function ObjectBase:__undoInitComplete__()
end

-- END: Setup Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


-- none



--====================================================================--
--== Private Methods


-- none



--====================================================================--
--== Event Handlers


-- none






--====================================================================--
--== Lua Objects Exports
--====================================================================--


-- simply add to current exports
Objects.ObjectBase = ObjectBase



return Objects


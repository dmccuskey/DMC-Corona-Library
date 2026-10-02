--====================================================================--
-- dmc_corona/dmc_lifecycle_mix.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-lifecycle-mixin
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2015 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : DMC Lifecycle Mixin
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.1"



--====================================================================--
--== Configuration


-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end



--====================================================================--
--== Setup, Constants


local tinsert, tremove = table.insert, table.remove
local sfmt = string.format
local assert, type = assert, type

local Utils
local Lifecycle



--====================================================================--
--== Support Functions


Utils = {}

function Utils.createObjectCallback( object, method )
	assert( object, "dmc_utils.createObjectCallback: missing object" )
	assert( method, "dmc_utils.createObjectCallback: missing method" )
	--==--
	return function( ... )
		return method( object, ... )
	end
end



-- create general output string
local function outStr( msg )
	return sfmt( "DMC Lifecycle (debug) :: %s", tostring(msg) )
end

-- create general error string
local function errStr( msg )
	return sfmt( "\n\n[ERROR] DMC Lifecycle ::  %s\n\n", tostring(msg) )
end




local function _patch( obj )

	obj = obj or {}

	-- add properties
	obj.LIFECYCLE_UPDATED = Lifecycle.LIFECYCLE_UPDATED
	obj.PROPERTY_UPDATED = Lifecycle.PROPERTY_UPDATED

	-- add methods
	-- a plain table has no setters, so onUpdate and onProperty are
	-- methods here: obj:onUpdate( func )
	obj.__undoInit__ = Lifecycle.__undoInit__
	obj.resetLifecycle = Lifecycle.resetLifecycle
	obj.onUpdate = Lifecycle.onUpdate
	obj.onProperty = Lifecycle.__setters.onProperty
	obj.__invalidateProperties__ = Lifecycle.__invalidateProperties__
	obj.__dispatchInvalidateNotification__ = Lifecycle.__dispatchInvalidateNotification__
	obj.__stopUpdate = Lifecycle.__stopUpdate
	obj.__invalidateNextFrame__ = Lifecycle.__invalidateNextFrame__
	obj.__enterFrame__ = Lifecycle.__enterFrame__
	obj.__validate__ = Lifecycle.__validate__
	obj.__commitProperties__ = obj.__commitProperties__ or Lifecycle.__commitProperties__

	obj.setDebug = Lifecycle.setDebug

	-- set up, once the methods are there
	Lifecycle.__init__( obj )

	return obj
end



--====================================================================--
--== Lifecycle Mixin
--====================================================================--


Lifecycle = {}

Lifecycle.__getters = {}
Lifecycle.__setters = {}

Lifecycle.NAME = "Lifecycle Mixin"

Lifecycle.LIFECYCLE_UPDATED = 'lifecycle-updated-event'
Lifecycle.PROPERTY_UPDATED = 'property-updated-event'


--======================================================--
-- Start: Mixin Setup for Lua Objects

function Lifecycle.__init__( self, params )
	-- print( "Lifecycle.__init__" )
	params = params or {}
	--==--
	Lifecycle.resetLifecycle( self, params )
end

function Lifecycle.__undoInit__( self )
	-- print( "Lifecycle.__undoInit__" )
	self:__stopUpdate()
	self.__enterFrame_f = nil
	if self.__setters then self.__setters.onUpdate = nil end
end

-- END: Mixin Setup for Lua Objects
--======================================================--



--====================================================================--
--== Public Methods


function Lifecycle.resetLifecycle( self, params )
	params = params or {}
	if params.debug_on==nil then params.debug_on=false end
	--==--
	if self.__debug_on then
		print( outStr( "resetLifecycle: resetting object states" ) )
	end

	self.__commit_dirty = false
	self.__pending_update = false
	assert( type(self.__enterFrame__)=='function' )
	self.__enterFrame_f = Utils.createObjectCallback( self, self.__enterFrame__ )
	self.__onUpdate = nil
	self.__onProperty = nil
	self.__debug_on = params.debug_on

	-- need to do these manually, because in setters/getters
	-- (a patched plain table has none: it calls obj:onUpdate( func ))
	if self.__setters then self.__setters.onUpdate = Lifecycle.onUpdate end
end


function Lifecycle.onUpdate( self, func )
	-- print( 'Lifecycle.onUpdate', func )
	local t = type(func)
	assert( t=='nil' or t=='function' )
	--==--
	self.__onUpdate = func
end

function Lifecycle.__setters.onProperty( self, func )
	-- print( 'Lifecycle.onProperty', func )
	local t = type(func)
	assert( t=='nil' or t=='function' )
	--==--
	self.__onProperty = func
end


function Lifecycle.__invalidateProperties__( self )
	-- print("Lifecycle.__invalidateProperties__")
	self.__commit_dirty = true
	self:__invalidateNextFrame__()
end

function Lifecycle.__dispatchInvalidateNotification__( self, prop, value )
	-- print("Lifecycle.__dispatchInvalidateNotification__", prop, value)
	local e = {
		name=self.EVENT,
		type=self.PROPERTY_UPDATED,
		target=self,
		property=prop,
		value=value
	}
	if self.__onProperty then self.__onProperty( e ) end
end


function Lifecycle.__stopUpdate( self )
	if self.__pending_update == true then
		Runtime:removeEventListener( 'enterFrame', self.__enterFrame_f )
	end
	self.__pending_update = false
end

function Lifecycle.__invalidateNextFrame__( self )
	-- print("Lifecycle.__invalidateNextFrame__")
	if self.__pending_update == true then return end
	self.__pending_update = true
	Runtime:addEventListener( 'enterFrame', self.__enterFrame_f )
end

function Lifecycle.__enterFrame__( self )
	self:__validate__()
end

function Lifecycle.__validate__( self )
	-- print("Lifecycle.__validate__")
	if self.__commit_dirty == true then
		self.__commit_dirty = false
		self:__commitProperties__()
		if self.__onUpdate then
			self.__onUpdate({name=self.EVENT, type=self.LIFECYCLE_UPDATED, target=self})
		end
	end
	-- a setter called during the update marked the object as changed
	-- again: keep listening, so that change is committed next frame
	if self.__commit_dirty ~= true then
		self:__stopUpdate()
	end
end

function Lifecycle.__commitProperties__( self )
	-- override this
end


function Lifecycle.setDebug( self, value )
	self.__debug_on = value
end



--====================================================================--
--== Lifecycle Facade
--====================================================================--


return {
	VERSION=VERSION,

	LifecycleMix=Lifecycle,

	patch=_patch,
}


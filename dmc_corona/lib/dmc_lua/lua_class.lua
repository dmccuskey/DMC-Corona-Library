--====================================================================--
-- dmc_lua/lua_class.lua
--
-- Documentation: https://github.com/dmccuskey/lua-class
--====================================================================--

--[[

The MIT License (MIT)

Copyright (c) 2015 David McCuskey

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

local VERSION = "0.2.0"



--====================================================================--
--== Imports


-- none



--====================================================================--
--== Setup, Constants


-- cache globals
local assert, type, rawget, rawset = assert, type, rawget, rawset
local getmetatable, setmetatable = getmetatable, setmetatable

local sformat = string.format
local tinsert = table.insert
local tremove = table.remove
local unpack = unpack or table.unpack

-- forward declare
local ClassBase



--====================================================================--
--== Class Support Functions


-- pack()
-- like table.pack(): keeps the count, so nil values survive unpack()
--
local function pack( ... )
	return { n=select( '#', ... ), ... }
end



-- registerCtorName
-- add names for the constructor
--
local function registerCtorName( name, class )
	class = class or ClassBase
	--==--
	assert( type( name ) == 'string', "ctor name should be string" )
	assert( class.is_class, "Class is not is_class" )

	class[ name ] = class.__ctor__
	return class[ name ]
end

-- registerDtorName
-- add names for the destructor
--
local function registerDtorName( name, class )
	class = class or ClassBase
	--==--
	assert( type( name ) == 'string', "dtor name should be string" )
	assert( class.is_class, "Class is not is_class" )

	class[ name ] = class.__dtor__
	return class[ name ]
end



--[[
obj:superCall( 'string', ... )
obj:superCall( Class, 'string', ... )
--]]

-- superCall()
-- function to intelligently find methods in object hierarchy
--
local function superCall( self, ... )
	local arg1 = ...
	assert( type(arg1)=='table' or type(arg1)=='string', "superCall arg not table or string" )
	--==--
	-- pick off arguments
	local parent_lock, method, args

	if type(arg1) == 'table' then
		parent_lock, method = ...
		args = pack( select( 3, ... ) )
	else
		method = arg1
		args = pack( select( 2, ... ) )
	end

	local self_dmc_super = self.__dmc_super
	local super_flag = ( self_dmc_super ~= nil )
	-- pcall() results: ok flag, then values
	-- nil, not nothing, when no method is called
	local result = pack( true, nil )

	-- finds method name in class hierarchy
	-- returns found class or nil
	-- @params classes list of Classes on which to look, table/list
	-- @params name name of method to look for, string
	-- @params lock Class object with which to constrain searching
	--
	local function findMethod( classes, name, lock )
		if not classes then return end -- when using mixins, etc
		local cls = nil
		for _, class in ipairs( classes ) do
			if not lock or class == lock then
				if rawget( class, name ) then
					cls = class
					break
				else
					-- check parents for method
					cls = findMethod( class.__parents, name )
					if cls then break end
				end
			end
		end
		return cls
	end

	local c, s  -- class, super

	-- structure in which to save our place
	-- in case superCall() is invoked again
	--
	if self_dmc_super == nil then
		self.__dmc_super = {} -- a stack
		self_dmc_super = self.__dmc_super
		-- find out where we are in hierarchy
		s = findMethod( { self.__class }, method )
		tinsert( self_dmc_super, s )
	end

	-- pull Class from stack and search for method on Supers
	-- look for method on supers
	-- call method if found
	--
	c = self_dmc_super[ # self_dmc_super ]

	-- c is nil when no class defines the method
	s = c and findMethod( c.__parents, method, parent_lock )
	if s then
		tinsert( self_dmc_super, s )
		-- pcall(), so an error can't leave our place behind on the object
		result = pack( pcall( s[method], self, unpack( args, 1, args.n ) ) )
		tremove( self_dmc_super, # self_dmc_super )
	end

	-- this is the first iteration and last
	-- so clean up callstack, etc
	--
	if super_flag == false then
		parent_lock = nil
		tremove( self_dmc_super, # self_dmc_super )
		self.__dmc_super = nil
	end

	-- pass the error on unchanged
	if not result[1] then error( result[2], 0 ) end

	return unpack( result, 2, result.n )
end



-- initializeObject
-- this is the beginning of object initialization
-- either Class or Instance
-- this is what calls the parent constructors, eg new()
-- called from newClass(), __create__(), __call()
--
-- @params obj the object context
-- @params params table with :
-- set_isClass = true/false
-- data contains {...}
--
local function initializeObject( obj, params )
	params = params or {}
	--==--
	assert( params.set_isClass ~= nil, "initializeObject requires paramter 'set_isClass'" )

	local is_class = params.set_isClass
	local args = params.data or pack()

	-- set Class/Instance flag
	obj.__is_class = params.set_isClass

	-- call Parent constructors, if any
	-- do in reverse
	--
	local parents = obj.__parents
	for i = #parents, 1, -1 do
		local parent = parents[i]
		assert( parent, "Lua Objects: parent is nil, check parent list" )

		rawset( obj, '__parent_lock', parent )
		if parent.__new__ then
			parent.__new__( obj, unpack( args, 1, args.n or #args ) )
		end

	end
	rawset( obj, '__parent_lock', nil )

	return obj
end



-- findAccessor()
-- find a getter or setter on an object or its parents,
-- in the same order as property lookup
--
-- @param t object table
-- @param name '__getters' or '__setters'
-- @param k key
--
local function findAccessor( t, name, k )
	local tbl = rawget( t, name )
	local f = tbl and rawget( tbl, k )
	if f then return f end

	local par = rawget( t, '__parents' )
	if not par then return nil end
	for i = 1, #par do
		f = findAccessor( par[i], name, k )
		if f then return f end
	end
	return nil
end



-- findValue()
-- find a key on a list of parents or their parents,
-- without calling their getters
--
-- @param parents list of Classes
-- @param k key
--
local function findValue( parents, k )
	for i = 1, #parents do
		local p = parents[i]
		local val
		if rawget( p, '__is_dmc' ) then
			val = rawget( p, k )
			if val == nil then
				local par = rawget( p, '__parents' )
				if par then val = findValue( par, k ) end
			end
		else
			val = p[k] -- not one of ours, use its own lookup
		end
		if val ~= nil then return val end
	end
	return nil
end



-- newindexFunc()
-- override the normal Lua lookup functionality to allow
-- property setter functions
--
-- @param t object table
-- @param k key
-- @param v value
--
local function newindexFunc( t, k, v )
	local f = findAccessor( t, '__setters', k )
	if f then
		-- found setter, so call it
		f( t, v )
	else
		-- place key/value directly on object
		rawset( t, k, v )
	end
end



-- multiindexFunc()
-- override the normal Lua lookup functionality to allow
-- property getter functions
-- (only called when the key isn't directly on the object)
--
-- @param t object table
-- @param k key
--
local function multiindexFunc( t, k )
	-- check for key in getters, on object or parents
	local f = findAccessor( t, '__getters', k )
	if f then return f( t ) end

	-- check OO hierarchy
	-- check Parent Lock else all of Parents
	--
	local lock = rawget( t, '__parent_lock' )
	if lock then
		return findValue( { lock }, k )
	end
	local par = rawget( t, '__parents' )
	if par then
		return findValue( par, k )
	end
	return nil
end



-- blessObject()
-- create new object, setup with Lua OO aspects, dmc-style aspects
-- @params inheritance table of supers/parents (dmc-style objects)
-- @params params
-- params.object
-- params.set_isClass
--
local function blessObject( inheritance, params )
	params = params or {}
	params.object = params.object or {}
	params.set_isClass = params.set_isClass == true and true or false
	--==--
	local o = params.object
	local o_id = tostring(o)
	local mt = {
		__index = multiindexFunc,
		__newindex = newindexFunc,
		__tostring = function(obj)
			return obj:__tostring__(o_id)
		end,
		__call = function( cls, ... )
			return cls:__ctor__( ... )
		end
	}
	setmetatable( o, mt )

	-- add Class property, access via getters:supers()
	o.__parents = inheritance
	o.__is_dmc = true

	-- create lookup tables - setters, getters
	-- parents' getters and setters are looked up when used,
	-- so ones added to a parent later are found too
	o.__setters = {}
	o.__getters = {}

	return o
end


local function unblessObject( o )
	setmetatable( o, nil )
	o.__parents=nil
	o.__is_dmc = nil
	o.__setters = nil
	o.__getters=nil
end


local function newClass( inheritance, params )
	inheritance = inheritance or {}
	params = params or {}
	params.set_isClass = true
	params.name = params.name or "<unnamed class>"
	--==--
	assert( type( inheritance ) == 'table', "first parameter should be nil, a Class, or a list of Classes" )

	-- wrap single-class into table list
	-- testing for DMC-Style objects
	-- TODO: see if we can test for other Class libs
	--
	if inheritance.is_class == true then
		inheritance = { inheritance }
	elseif ClassBase and #inheritance == 0 then
		-- add default base Class
		tinsert( inheritance, ClassBase )
	end

	local o = blessObject( inheritance, {} )

	initializeObject( o, params )

	-- add Class property, access via getters:class()
	o.__class = o

	-- add Class property, access via getters:NAME()
	o.__name = params.name

	return o

end


-- backward compatibility
--
local function inheritsFrom( baseClass, options, constructor )
	baseClass = baseClass == nil and baseClass or { baseClass }
	return newClass( baseClass, options )
end



--====================================================================--
--== Base Class
--====================================================================--


ClassBase = newClass( nil, { name="Class Class" } )

-- __ctor__ method
-- called by 'new()' and other registrations
--
function ClassBase:__ctor__( ... )
	local params = {
		data = pack( ... ),
		set_isClass = false
	}
	--==--
	local o = blessObject( { self.__class }, params )
	initializeObject( o, params )

	return o
end

-- __dtor__ method
-- called by 'destroy()' and other registrations
--
function ClassBase:__dtor__()
	self:__destroy__()
	-- unblessObject( self )
end


function ClassBase:__new__( ... )
	return self
end


function ClassBase:__tostring__( id )
	return sformat( "%s (%s)", self.NAME, id )
end


function ClassBase:__destroy__()
end


function ClassBase.__getters:NAME()
	return self.__name
end


function ClassBase.__getters:class()
	return self.__class
end

function ClassBase.__getters:supers()
	return self.__parents
end


function ClassBase.__getters:is_class()
	return self.__is_class
end

-- deprecated
function ClassBase.__getters:is_intermediate()
	return self.__is_class
end

function ClassBase.__getters:is_instance()
	return not self.__is_class
end

function ClassBase.__getters:version()
	return self.__version
end


function ClassBase:isa( the_class )
	local isa = false
	local cur_class = self.class

	-- test self
	if cur_class == the_class then
		isa = true

	-- test parents
	else
		local parents = self.__parents
		for i=1, #parents do
			local parent = parents[i]
			if parent.isa then
				isa = parent:isa( the_class )
			end
			if isa == true then break end
		end
	end

	return isa
end


-- optimize()
-- move super class methods to object
--
function ClassBase:optimize()

	local function _optimize( obj, inheritance )

		if not inheritance or #inheritance == 0 then return end

		for i=#inheritance,1,-1 do
			local parent = inheritance[i]

			-- climb up the hierarchy
			_optimize( obj, parent.__parents )

			-- make local references to all functions
			for k,v in pairs( parent ) do
				if type( v ) == 'function' then
					obj[ k ] = v
				end
			end
		end

	end

	_optimize( self, { self.__class } )
end

-- deoptimize()
-- remove super class (optimized) methods from object
--
function ClassBase:deoptimize()
	for k,v in pairs( self ) do
		if type( v ) == 'function' then
			self[ k ] = nil
		end
	end
end



-- Setup Class Properties (function references)

registerCtorName( 'new', ClassBase )
registerDtorName( 'destroy', ClassBase )
ClassBase.superCall = superCall




--====================================================================--
--== Lua Objects Exports
--====================================================================--


-- makeNewClassGlobal
-- modifies the global namespace with newClass()
-- add (true or nil) or remove (false)
-- a global newClass from elsewhere is left alone
--
local function makeNewClassGlobal( is_global )
	if is_global == nil then is_global = true end
	if _G.newClass ~= nil and _G.newClass ~= newClass then
		print( "WARNING: newClass exists in global namespace" )
	elseif is_global then
		_G.newClass = newClass
	else
		_G.newClass = nil
	end
end

makeNewClassGlobal() -- start it off


return {
	__version=VERSION,
	__superCall=superCall, -- for testing
	setNewClassGlobal=makeNewClassGlobal,

	registerCtorName=registerCtorName,
	registerDtorName=registerDtorName,

	inheritsFrom=inheritsFrom, -- backwards compatibility
	newClass=newClass,

	Class=ClassBase
}

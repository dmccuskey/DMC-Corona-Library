--====================================================================--
-- dmc_lua/lua_class.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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

local VERSION = "0.1.0"



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

-- table for copies from lua_utils
local Utils = {}

-- forward declare
local ClassBase



--====================================================================--
--== Class Support Functions


--== Start: copy from lua_utils ==--

-- extend()
-- Copy key/values from one table to another
-- Will deep copy any value from first table which is itself a table.
--
-- @param fromTable the table (object) from which to take key/value pairs
-- @param toTable the table (object) in which to copy key/value pairs
-- @return table the table (object) that received the copied items
--
function Utils.extend( fromTable, toTable )

	if not fromTable or not toTable then
		error( "table can't be nil" )
	end
	function _extend( fT, tT )

		for k,v in pairs( fT ) do

			if type( fT[ k ] ) == "table" and
				type( tT[ k ] ) == "table" then

				tT[ k ] = _extend( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == "table" then
				tT[ k ] = _extend( fT[ k ], {} )

			else
				tT[ k ] = v
			end
		end

		return tT
	end

	return _extend( fromTable, toTable )
end

--== End: copy from lua_utils ==--




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
	local args = {...}
	local arg1 = args[1]
	assert( type(arg1)=='table' or type(arg1)=='string', "superCall arg not table or string" )
	--==--
	-- pick off arguments
	local parent_lock, method, params

	if type(arg1) == 'table' then
		parent_lock = tremove( args, 1 )
		method = tremove( args, 1 )
	else
		method = tremove( args, 1 )
	end
	params = args

	local self_dmc_super = self.__dmc_super
	local super_flag = ( self_dmc_super ~= nil )
	local result = nil

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
	-- TODO: when c==nil
	-- if c==nil or type(c)~='table' then return end

	s = findMethod( c.__parents, method, parent_lock )
	if s then
		tinsert( self_dmc_super, s )
		result = s[method]( self, unpack( args ) )
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

	return result
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
	local args = params.data or {}

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
			parent.__new__( obj, unpack( args ) )
		end

	end
	rawset( obj, '__parent_lock', nil )

	return obj
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

	local o, f

	-- check for key in setters table
	o = rawget( t, '__setters' ) or {}
	f = o[k]
	if f then
		-- found setter, so call it
		f(t,v)
	else
		-- place key/value directly on object
		rawset( t, k, v )
	end

end



-- multiindexFunc()
-- override the normal Lua lookup functionality to allow
-- property getter functions
--
-- @param t object table
-- @param k key
--
local function multiindexFunc( t, k )

	local o, val

	--== do key lookup in different places on object

	-- check for key in getters table
	o = rawget( t, '__getters' ) or {}
	if o[k] then return o[k](t) end

	-- check for key directly on object
	val = rawget( t, k )
	if val ~= nil then return val end

	-- check OO hierarchy
	-- check Parent Lock else all of Parents
	--
	o = rawget( t, '__parent_lock' )
	if o then
		if o then val = o[k] end
		if val ~= nil then return val end
	else
		local par = rawget( t, '__parents' )
		for _, o in ipairs( par ) do
			if o[k] ~= nil then
				val = o[k]
				break
			end
		end
		if val ~= nil then return val end
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
	o.__setters = {}
	o.__getters = {}

	-- copy down all getters/setters of parents
	-- do in reverse order, to match order of property lookup
	for i = #inheritance, 1, -1 do
		local cls = inheritance[i]
		if cls.__getters then
			o.__getters = Utils.extend( cls.__getters, o.__getters )
		end
		if cls.__setters then
			o.__setters = Utils.extend( cls.__setters, o.__setters )
		end
	end

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
		data = {...},
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

	function _optimize( obj, inheritance )

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
-- add or remove
--
local function makeNewClassGlobal( is_global )
	is_global = is_global~=nil and is_global or true
	if _G.newClass ~= nil then
		print( "WARNING: newClass exists in global namespace" )
	elseif is_global == true then
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

--====================================================================--
-- dmc_corona/dmc_autostore.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-autostore
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2013-2015 David McCuskey. All Rights Reserved.

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
--== DMC Corona Library : AutoStore
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "2.2.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--


--====================================================================--
--== Configuration

local dmc_lib_data, dmc_lib_info

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_corona

local Utils = require 'lib.dmc_lua.lua_utils'



--====================================================================--
--== DMC AutoStore
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_autostore = dmc_lib_data.dmc_autostore or {}

local DMC_AUTOSTORE_DEFAULTS = {
	debug_active = false,
	data_filename = 'dmc_autostore',
	plugin_file = nil,
	timer_min = 1000,
	timer_max = 4000
}

local dmc_autostore_data = Utils.extend( dmc_lib_data.dmc_autostore, DMC_AUTOSTORE_DEFAULTS )



--====================================================================--
--== Imports


local json = require 'json'
local Files = require 'dmc_files'
local Objects = require 'dmc_objects'



--====================================================================--
--== Setup, Constants


-- aliases to make code cleaner
local newClass = Objects.newClass
local ObjectBase = Objects.ObjectBase


-- STATE_ACTIVE flag
-- false when initializing, true when everything is loaded
-- so that changes in data don't fire AutoStore saving
-- will be true after main branch is initialized
--
local STATE_ACTIVE = false


-- need to pre-declare these so everything syncs

local addPixieDust
local AutoStore, autostore_singleton = nil
local TableProxy
local createTableProxy



--====================================================================--
--== Table Proxy Support Functions


-- mtIndexFunc
-- enhanced metatable lookup function
--
local function mtIndexFunc( t, k )
	--print( "mtIndexFunc: " .. tostring( t ) .. " " .. tostring( k ) )

	local val

	-- for lookup, let's do Table Proxy, then the table

	-- check TableProxy Class
	val = TableProxy[ k ]

	if val == nil then
		-- nothing, so check the table
		val = getmetatable( t ).__dmc.dt[ k ]

		-- we have a value, but if the value is of type "table"
		-- then we need to use its proxy
		-- (wrapped here if it was added through a stored table)
		if type( val ) == "table" then
			val = addPixieDust( val )
		end
	end

	return val
end


-- storableValue()
-- a stand-in can't be stored: store a copy of its data
-- (the file can't hold one table under two keys anyway)
-- unless it's the table already there ( t.a = t.a )
--
local function storableValue( v, current )
	local mt = getmetatable( v )
	if type( v ) == "table" and mt and mt.__index == mtIndexFunc then
		if mt.__dmc.dt == current then return current end
		return Utils.extend( mt.__dmc.dt, {} )
	end
	return v
end


-- mtNewIndexFunc
-- enhanced metatable set function
--
local function mtNewIndexFunc( t, k, v )
	--print( "mtNewIndexFunc" )
	local mt = getmetatable( t )
	local dmc = mt ~= nil and mt.__dmc or nil

	assert( type(dmc)=='table', "AutoStore: eeks, deep dark error" )

	v = storableValue( v, dmc.dt[ k ] )
	dmc.dt[ k ] = v
	if type( v ) == "table" then
		--print( "found table: " .. tostring( k ) .. " : " .. tostring( v ) )
		addPixieDust( v )
	end

	if STATE_ACTIVE == true then dmc.root:_markDirty() end

end


-- createTableProxy()
-- creates the "magic" handle for data retrieval
-- 'data_table' is actual Lua table in original data structure
--
createTableProxy = function( data_table )
	--print( "CreateTableProxy" )

	local magic = {} -- this is to be empty, always

	-- references to important data
	local refs = {
		dt = data_table,
		root = autostore_singleton,
	}

	-- our metable to store on data handle
	local mt = {
		__index = mtIndexFunc,
		__newindex = mtNewIndexFunc,
		__dmc = refs
	}
	setmetatable( magic, mt )

	return magic
end


-- addPixieDust()
-- wraps all data with Table Proxy
-- a table already wrapped keeps its proxy
--
addPixieDust = function( data_table )
	-- print( "adding pixie dust: " .. tostring( data_table ) )

	local mt = getmetatable( data_table )
	if mt and mt.__dmc and mt.__dmc.prx then return mt.__dmc.prx end

	-- hiding our info on the metatable
	local proxy = createTableProxy( data_table )

	-- references to important data
	local refs = {
			prx = proxy
	}

	-- our metable to store on data table
	mt = {
		__dmc = refs
	}
	setmetatable( data_table, mt )

	-- check children to make sure they all have magic pixie dust
	for _, v in pairs( data_table ) do
		if type( v ) == "table" then
			--print( tostring( _ ) .. " >> " .. tostring( v ) )
			addPixieDust( v )
		end
	end

	return proxy
end



--====================================================================--
--== Table Proxy Class
--====================================================================--


--[[
This mixin-class allows us to add functionality
to a data table node when doing lookup.
This essentially adds additional 'API' to each node
--]]

TableProxy = {}
TableProxy.NAME = "Table Proxy"



--====================================================================--
--== Private Methods


-- __data()
-- gets the raw data from the proxy
-- used primarily when encoding JSON
--
function TableProxy:__data()
	--print( "TableProxy:__data" )
	local mt = getmetatable( self )
	return mt.__dmc.dt
end



--====================================================================--
--== Public Methods


--[[
The following are methods to interface with the Lua table library
since the table library doesn't "eat its own dogfood"
--]]


-- clone()
-- convert autostore data back into regular Lua table
-- this makes a deep copy
--
function TableProxy:clone()
	-- print( "TableProxy:clone" )
	local mt = getmetatable( self )
	return Utils.extend( mt.__dmc.dt, {} )
end

-- len()
-- get the length of the table
-- replacement for table.len( tbl )
-- or #tbl
--
function TableProxy:len()
	--print( "TableProxy:len" )
	local mt = getmetatable( self )
	local dt = mt.__dmc.dt

	return #dt
end

-- ipairs()
-- use this in an array-type iteration
--
function TableProxy:ipairs()
	--print( "TableProxy:ipairs" )

	-- custom iterator
	-- @param tp ref: TableProxy (ie, self)
	-- @param i integer: index of item to get
	local f = function( tp, i )
		i = i+1
		local v = tp[i]
		if v ~= nil then
			return i,v
		else
			return nil
		end
	end

	return f, self, 0
end

-- pairs()
-- use this in an hash-type iteration
--
function TableProxy:pairs()
	--print( "TableProxy:pairs" )

	local mt = getmetatable( self )
	local dt = mt.__dmc.dt

	-- custom iterator
	-- @param tp ref: TableProxy (ie, self)
	-- @param key string: key of previous item
	local f = function( tp, k )
		local key,val = next( dt, k )
		if key ~= nil then
			if type( val ) == "table" then val = addPixieDust( val ) end
			return key,val
		else
			return nil
		end
	end

	return f, self, nil
end

-- insert()
-- insert a value into the table
--
function TableProxy:insert( value, pos )
	--print( "TableProxy:insert" )
	local mt = getmetatable( self )

	local root = mt.__dmc.root
	local dt = mt.__dmc.dt

	value = storableValue( value )
	if pos == nil then
		table.insert( dt, value )
	else
		table.insert( dt, pos, value )
	end

	if type( value ) == "table" then
		addPixieDust( value )
	end

	if STATE_ACTIVE == true then root:_markDirty() end
end

-- remove()
-- remove a value from the table
--
function TableProxy:remove( pos )
	--print( "TableProxy:remove" )
	local mt = getmetatable( self )

	local root = mt.__dmc.root
	local dt = mt.__dmc.dt

	if STATE_ACTIVE == true then root:_markDirty() end

	if pos == nil then
		return table.remove( dt )
	else
		return table.remove( dt, pos )
	end

end



--====================================================================--
--== AutoStore Class
--====================================================================--


local AutoStore = newClass( ObjectBase, { name="AutoStore" } )

--== Class Constants ==--

AutoStore.VERSION = VERSION

--== Event Constants ==--

AutoStore.EVENT = 'autostore_event'

AutoStore.START_MIN_TIMER = 'start_min_timer'
AutoStore.STOP_MIN_TIMER = 'stop_min_timer'
AutoStore.START_MAX_TIMER = 'start_max_timer'
AutoStore.STOP_MAX_TIMER = 'stop_max_timer'
AutoStore.DATA_SAVED = 'data_saved'


--======================================================--
-- Start: Setup DMC Objects

function AutoStore:__init__( ... )
	-- print( "AutoStore:__init__" )
	self:superCall( ObjectBase, '__init__', ... )
	--==--

	--== Create Properties ==--

	self._data = nil
	self._is_new_file = false
	self._is_dirty = false -- changes not yet in the file

	self.__debug_on = false

	-- timer references
	self._timer_min = nil
	self._timer_max = nil

	self._preSave_f = nil
	self._postRead_f = nil

	self._system_f = nil

end


function AutoStore:__initComplete__()
	-- print( "AutoStore:__initComplete__" )
	self:superCall( ObjectBase, '__initComplete__' )
	--==--

	STATE_ACTIVE = false

	self.__debug_on = dmc_autostore_data.debug_active == true

	self:_checkTimerValues()
	self:_loadPlugins()

	-- save what's left before the app is suspended or quits
	self._system_f = function( event )
		if event.type == 'applicationSuspend' or event.type == 'applicationExit' then
			self:save()
		end
	end
	Runtime:addEventListener( 'system', self._system_f )

end

-- END: Setup DMC Objects
--======================================================--



--====================================================================--
--== Public Methods


function AutoStore.__getters:is_new_file()
	return self._is_new_file
end

function AutoStore.__getters:data()
	return self._data
end

function AutoStore.__setters:debug( value )
	self.__debug_on = value
end


-- save()
-- write unsaved changes now, rather than when a timer fires
-- returns false if the file couldn't be written
--
function AutoStore:save()
	-- print( "AutoStore:save" )

	self:_stopMinTimer()
	self:_stopMaxTimer()

	if not self._is_dirty then return true end
	return self:_saveData()
end



--====================================================================--
--== Private Methods


-- _checkTimerValues()
-- make sure that the timer values work well
--
function AutoStore:_checkTimerValues()
	local dmc = dmc_autostore_data

	assert( type(dmc.timer_min)=='number', "AutoStore: TIMER MIN not a number" )
	assert( type(dmc.timer_max)=='number', "AutoStore: TIMER MAX not a number" )
	assert( dmc.timer_min >=0, "AutoStore: TIMER MIN not >= 0" )
	assert( dmc.timer_min < dmc.timer_max, "AutoStore: TIMER MIN > TIMER MAX" )
end


-- _getDataFilePath()
-- create full path name for file read/write
--
function AutoStore:_getDataFilePath( suffix )
	local file_name = dmc_autostore_data.data_filename .. ( suffix or '' ) .. '.json'
	local file_path = system.pathForFile( file_name, system.DocumentsDirectory )

	return file_path
end


-- _loadPlugins()
-- load and save contents of plugin file
--
function AutoStore:_loadPlugins()
	-- print( "AutoStore:_loadPlugins" )

	if not dmc_autostore_data.plugin_file then return end

	if self.__debug_on then
		print( "AutoStore: Loading plugin file", dmc_autostore_data.plugin_file )
	end

	local plugin = require( dmc_autostore_data.plugin_file )
	assert( type(plugin)=='table', "AutoStore: plugin file must return a table" )

	if plugin.preSaveFunction then self._preSave_f = plugin.preSaveFunction end
	if plugin.postReadFunction then self._postRead_f = plugin.postReadFunction end

end


-- _loadData()
-- loads data from JSON format
-- a file which can't be read is moved aside, not overwritten
--
function AutoStore:_loadData()
	-- print( "AutoStore:_loadData" )

	local file_path = self:_getDataFilePath()
	local fh = io.open( file_path, 'r' )
	local data

	if fh then
		fh:close()
		local ok, result = pcall( function()
			local contents = Files.readFileContents( file_path )
			if self._postRead_f then contents = self._postRead_f( contents ) end
			return json.decode( contents )
		end )
		if ok and type( result ) == 'table' then
			data = result
		else
			local bad_path = self:_getDataFilePath( '.bad' )
			os.remove( bad_path )
			os.rename( file_path, bad_path )
			print( "AutoStore: can't read the data file, moved it to " .. bad_path )
			if not ok then print( "AutoStore:", result ) end
		end
	end

	if data then
		self._is_new_file = false
		self._data = addPixieDust( data )
	else
		self._is_new_file = true
		self._data = addPixieDust( {} )
	end

	if self.__debug_on then
		print( "AutoStore: Loaded data, new file:", self._is_new_file )
	end

	STATE_ACTIVE = true

end


-- _saveData()
-- saves data into JSON format
-- on an error the changes stay unsaved, for the next save
--
function AutoStore:_saveData()
	-- print( "AutoStore:_saveData" )

	local file_path = self:_getDataFilePath()

	local ok, err = pcall( function()
		local data = json.encode( self._data:__data() )
		if self._preSave_f then data = self._preSave_f( data ) end
		Files.saveFile( file_path, data )
	end )

	if not ok then
		print( "AutoStore: error saving file", err )
		return false
	end

	self._is_dirty = false
	self._is_new_file = false

	if self.__debug_on then
		print( "AutoStore: Saved data", file_path )
	end

	self:dispatchEvent( self.DATA_SAVED )
	return true
end


function AutoStore:_stopMinTimer()
	-- print( "AutoStore:_stopMinTimer" )

	if self._timer_min == nil then return end

	timer.cancel( self._timer_min )
	self:dispatchEvent( self.STOP_MIN_TIMER )
	self._timer_min = nil
end

function AutoStore:_startMinTimer( )
	-- print( "AutoStore:_startMinTimer" )

	self:_stopMinTimer()

	local f = function()
		self:save()
	end
	self._timer_min = timer.performWithDelay( dmc_autostore_data.timer_min, f )
	self:dispatchEvent( self.START_MIN_TIMER, { time=dmc_autostore_data.timer_min }, { merge=true } )

end


function AutoStore:_stopMaxTimer()
	-- print( "AutoStore:_stopMaxTimer" )

	if self._timer_max == nil then return end

	timer.cancel( self._timer_max )
	self:dispatchEvent( self.STOP_MAX_TIMER )
	self._timer_max = nil
end

function AutoStore:_startMaxTimer( )
	-- print( "AutoStore:_startMaxTimer" )

	self:_stopMaxTimer()

	local f = function()
		self:save()
	end
	self._timer_max = timer.performWithDelay( dmc_autostore_data.timer_max, f )
	self:dispatchEvent( self.START_MAX_TIMER, { time=dmc_autostore_data.timer_max }, { merge=true } )

end


-- _markDirty()
-- sets timers in motion to save data
--
function AutoStore:_markDirty()
	-- print( "AutoStore:_markDirty" )

	self._is_dirty = true

	self:_startMinTimer()

	if self._timer_max == nil then
		self:_startMaxTimer()
	end

end




--===================================================================--
-- Singleton Setup
--===================================================================--


--== Create Singleton ==--

autostore_singleton = AutoStore:new()
autostore_singleton:_loadData()


return autostore_singleton


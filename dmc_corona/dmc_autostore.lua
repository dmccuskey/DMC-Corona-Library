--====================================================================--
-- dmc_corona/dmc_autostore.lua
--
-- Documentation: http://docs.davidmccuskey.com/
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

local VERSION = "2.1.0"



--====================================================================--
--== DMC Corona Library Config
--====================================================================--


--====================================================================--
--== Support Functions


local Utils = {} -- make copying from Utils easier


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



--====================================================================--
--== DMC AutoStore
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_autostore = dmc_lib_data.dmc_autostore or {}

local DMC_AUTOSTORE_DEFAULTS = {
	data_filename = 'dmc_autostore',
	plugin_file = nil,
	timer_min = 1000,
	timer_max = 4000
}

local dmc_autostore_data = Utils.extend( dmc_lib_data.dmc_autostore, DMC_AUTOSTORE_DEFAULTS )



--====================================================================--
--== Imports


local json = require 'json'
local Error = require 'lib.dmc_lua.lua_error'
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

	local val, mt

	-- for lookup, let's do Table Proxy, then the table

	-- check TableProxy Class
	val = TableProxy[ k ]

	if val == nil then
		-- nothing, so check the table
		mt = getmetatable( t )
		val = mt.__dmc.dt[ k ]

		-- we have a value, but if the value is of type "table"
		-- then we need to use its proxy
		if type( val ) == "table" then
			--print( "getting next table" )
			mt = getmetatable( val )
			val = mt.__dmc.prx
		end
	end

	return val
end


-- mtNewIndexFunc
-- enhanced metatable set function
--
local function mtNewIndexFunc( t, k, v )
	--print( "mtNewIndexFunc" )
	local mt = getmetatable( t )
	local dmc = mt ~= nil and mt.__dmc or nil

	assert( type(dmc)=='table', "AutoStore: eeks, deep dark error" )

	dmc.dt[ k ] = v
	if type( v ) == "table" then
		--print( "found table: " .. tostring( k ) .. " : " .. tostring( v ) )
		local p = addPixieDust( v, t )
	end

	if dmc ~= nil and STATE_ACTIVE == true then dmc.root:_markDirty() end

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
--
addPixieDust = function( data_table, parent )
	-- print( "adding pixie dust: " .. tostring( data_table ) )

	-- hiding our info on the metatable
	local proxy = createTableProxy( data_table )

	-- references to important data
	local refs = {
			prx = proxy
	}

	-- our metable to store on data table
	local mt = {
		__dmc = refs
	}
	setmetatable( data_table, mt )

	-- check children to make sure they all have magic pixie dust
	if type( data_table ) == "table" then
		for _, v in pairs( data_table ) do
			if type( v ) == "table" then
				--print( tostring( _ ) .. " >> " .. tostring( v ) )
				local p = addPixieDust( v, data_table )
			end
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
	local dt = mt.__dmc.dt

	local _extendTable -- forward declare, recursive

	_extendTable = function( fT, tT )

		for k,v in pairs( fT ) do
			if type( fT[ k ] ) == 'table' and
				type( tT[ k ] ) == 'table' then
				tT[ k ] = _extendTable( fT[ k ], tT[ k ] )

			elseif type( fT[ k ] ) == 'table' then
				tT[ k ] = _extendTable( fT[ k ], {} )

			else
				tT[ k ] = v

			end
		end

		return tT
	end

	return _extendTable( dt, {} )
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
		local key,_ = next( dt, k )
		if key ~= nil then
			return key,tp[key]
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

	if pos == nil then
		table.insert( dt, value )
	else
		table.insert( dt, pos, value )
	end

	if type( value ) == "table" then
		p = addPixieDust( value, dt )
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

AutoStore.CONFIG_FILE = 'dmc_autostore.cfg'

--== Event Constants ==--

AutoStore.EVENT = 'autostore_event'

AutoStore.START_MIN_TIMER = 'start_min_timer'
AutoStore.STOP_MIN_TIMER = 'stop_min_timer'
AutoStore.START_MAX_TIMER = 'start_max_timer'
AutoStore.STOP_MAX_TIMER = 'stop_max_timer'
AutoStore.DATA_SAVED = 'data_saved'


--======================================================--
-- Start: Setup DMC Objects

function AutoStore:__init__()
	-- print( "AutoStore:__init__" )

	--== Create Properties ==--

	self._data = nil
	self._is_new_file = false

	self.__debug_on = false

	-- timer references
	self._timer_min = nil
	self._timer_max = nil

	self._preSave_f = nil
	self._postRead_f = nil

end


function AutoStore:__initComplete__()
	-- print( "AutoStore:__initComplete__" )

	STATE_ACTIVE = false

	self:_checkTimerValues()
	self:_loadPlugins()

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
function AutoStore:_getDataFilePath()
	local file_name = dmc_autostore_data.data_filename .. '.json'
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
--
function AutoStore:_loadData()
	-- print( "AutoStore:_loadData" )

	local file_path = self:_getDataFilePath()
	local data

	try{
		function()
			data = Files.readFileContents( file_path )
			if self._postRead_f then data = self._postRead_f( data ) end
			data = json.decode( data )
			self._is_new_file = false
			self._data = addPixieDust( data )
		end,

		catch{
			function( err )
				self._is_new_file = true
				self._data = addPixieDust( {} )
			end
		}
	}

	STATE_ACTIVE = true

end


-- _saveData()
-- saves data into JSON format
--
function AutoStore:_saveData()
	-- print( "AutoStore:_saveData" )

	local file_path = self:_getDataFilePath()
	local data

	try{
		function()
			data = json.encode( self._data:__data() )
			if self._preSave_f then data = self._preSave_f( data ) end
			Files.saveFile( file_path, data )
			self._is_new_file = false
			self:dispatchEvent( self.DATA_SAVED )
		end,

		catch{
			function( err )
				print( "AutoStore: error saving file" )
				error( err )
			end
		}
	}

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
		self:_stopMinTimer()
		self:_stopMaxTimer()
		self:_saveData()
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
		self:_stopMinTimer()
		self:_stopMaxTimer()
		self:_saveData()
	end
	self._timer_max = timer.performWithDelay( dmc_autostore_data.timer_max, f )
	self:dispatchEvent( self.START_MAX_TIMER, { time=dmc_autostore_data.timer_max }, { merge=true } )

end


-- _markDirty()
-- sets timers in motion to save data
--
function AutoStore:_markDirty()
	-- print( "AutoStore:_markDirty" )

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


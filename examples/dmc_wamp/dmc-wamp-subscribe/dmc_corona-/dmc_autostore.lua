--====================================================================--
-- dmc_autostore.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_autostore.lua
--====================================================================--

--[[

Copyright (C) 2013 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]



--====================================================================--
-- DMC Corona Library : DMC Autostore
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.1.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


--====================================================================--
-- Support Functions

local Utils = {} -- make copying from dmc_utils easier

function Utils.extend( fromTable, toTable )

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


--====================================================================--
-- Configuration

local dmc_lib_data, dmc_lib_info

-- boot dmc_library with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( "dmc_corona_boot" ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona
dmc_lib_info = dmc_lib_data.dmc_library



--====================================================================--
-- DMC Autostore
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_autostore = dmc_lib_data.dmc_autostore or {}

local DMC_AUTOSTORE_DEFAULTS = {
	debug_active=false,
}

local dmc_states_data = Utils.extend( dmc_lib_data.dmc_autostore, DMC_AUTOSTORE_DEFAULTS )


--====================================================================--
-- Imports

local json = require 'json'



--====================================================================--
-- Setup, Constants
--====================================================================--

-- flag, false when initializing, true when everything is loaded
-- so that changes in data don't fire AutoStore saving
local STATE_ACTIVE = false -- will be true after main branch is initialized


-- need to pre-declare these so everything syncs

local addPixieDust
local AutoStore
local autostore_singleton = nil
local TableProxy
local createTableProxy


--====================================================================--
-- Support Functions


-- extend()
-- copied from DMC Utils
-- only used during event dispatch
--
function extend( fromTable, toTable )

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


--====================================================================--
-- Base File I/O Functions

-- read/write flags
local Response = {}
Response.ERROR = "io_error"
Response.SUCCESS = "io_success"


-- basic read/write functions in Lua
-- options.lines = true
-- options.lines = false
local function readFile( file_path, options )
	local opts = options or {}
	if opts.lines == nil then opts.lines = true end

	local contents = {}
	local ret_val = {} -- an array, [ status, content ]

	if file_path == nil then
		local ret_val = { Response.ERROR, "file path is NIL" }
	else
		local fh, reason = io.open( file_path, "r" )
		if fh then
			-- read all contents of file into a table
			for line in fh:lines() do
				table.insert( contents, line )
			end
			io.close( fh )
			if opts.lines == true then
				ret_val = { Response.SUCCESS, contents }
			else
				ret_val = { Response.SUCCESS, table.concat( contents, "" ) }
			end
		else
			print("ERROR: datastore load settings: " .. tostring( reason ) )
			ret_val = { Response.ERROR, reason }
		end
	end
	return ret_val[1], ret_val[2]
end


local function saveFile( file_path, data )
	local ret_val = {} -- an array, [ status, content ]

	local fh, reason = io.open( file_path, "w" )
	if fh then
		fh:write( data )
		io.close( fh )
		ret_val = { Response.SUCCESS, contents }
	else
		print("ERROR: datastore save settings: " .. tostring( reason ) )
		ret_val = { Response.ERROR, reason }
	end
	return ret_val

end



--====================================================================--
-- Table Proxy Setup
--====================================================================--

-- functionality for each table node in the data structure


-- addPixieDust()
--
--
addPixieDust = function( obj, parent )
	--print( "adding pixie dust: " .. tostring( obj ) )

	-- hiding our info on the metatable
	local proxy = createTableProxy( obj )
	local mt = {}
	mt.__dmc = {
		p = proxy
	}
	setmetatable( obj, mt )


	-- check children to make sure they all have magic pixie dust

	local p
	if type( obj ) == "table" then
		for k, v in pairs( obj ) do
			if type( v ) == "table" then
				--print( tostring( k ) .. " >> " .. tostring( v ) )
				p = addPixieDust( v, obj )
			end
		end
	end

	return proxy
end


local function mtIndexFunc( t, k )
	--print( "mtIndexFunc: " .. tostring( t ) .. " " .. tostring( k ) )

	local val, mt

	-- for lookup, let's do Table Proxy, then the table

	-- check Table Proxy
	val = TableProxy[ k ]

	if val == nil then
		-- nothing, so check the table
		mt = getmetatable( t )
		val = mt.__dmc.t[ k ]

		-- we have a value, but if the value is of type "table"
		-- then we need to use its proxy
		if type( val ) == "table" then
			--print( "getting next table" )
			mt = getmetatable( val )
			val = mt.__dmc.p
		end
	end

	return val
end


local function mtNewIndexFunc( t, k, v )
	--print( "mtNewIndexFunc" )
	local mt = getmetatable( t )
	local dmc = mt ~= nil and mt.__dmc or nil

	dmc.t[ k ] = v
	local p
	if type( v ) == "table" then
		--print( "found table: " .. tostring( k ) .. " : " .. tostring( v ) )
		p = addPixieDust( v, t )
	end

	if dmc ~= nil and STATE_ACTIVE == true then dmc.root:isDirty() end

end


--=======================--
--== Table Proxy Class ==--

TableProxy = {}
TableProxy.NAME = "Table Proxy"

-- __data()
-- gets the raw data from the proxy. used primarily when encoding JSON
--
function TableProxy:__data()
	--print( "TableProxy:__data" )
	local mt = getmetatable( self )
	return mt.__dmc.t
end


-- The following are methods to interface with the table library
-- since the table library doesn't "eat its own dogfood"


-- len()
--
-- get the length of the table
-- replacement for table.len( tbl )
--
function TableProxy:len()
	--print( "TableProxy:len" )
	local mt = getmetatable( self )
	local t = mt.__dmc.t

	return #t
end

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

function TableProxy:pairs()
	--print( "TableProxy:pairs" )

	local mt = getmetatable( self )
	local t = mt.__dmc.t

	-- custom iterator
	-- @param tp ref: TableProxy (ie, self)
	-- @param key string: key of previous item
	local f = function( tp, k )
		local key,_ = next( t, k )
		if key ~= nil then
			return key,tp[key]
		else
			return nil
		end
	end

	return f, self, nil
end

function TableProxy:insert( value, pos )
	--print( "TableProxy:insert" )
	local mt = getmetatable( self )

	local root = mt.__dmc.root
	local t = mt.__dmc.t

	if pos == nil then
		table.insert( t, value )
	else
		table.insert( t, pos, value )
	end

	if type( value ) == "table" then
		p = addPixieDust( value, t )
	end

	if STATE_ACTIVE == true then root:isDirty() end
end

function TableProxy:remove( pos )
	--print( "TableProxy:remove" )
	local mt = getmetatable( self )

	local root = mt.__dmc.root
	local t = mt.__dmc.t

	if STATE_ACTIVE == true then root:isDirty() end

	if pos == nil then
		return table.remove( t )
	else
		return table.remove( t, pos )
	end

end

-- createTableProxy()
--
--
createTableProxy = function( table_obj )
	--print( "CreateTableProxy" )
	local o = {} -- this is to be empty, always
	local mt = {
		__index = mtIndexFunc,
		__newindex = mtNewIndexFunc
	}
	-- so let's store some data in the metatable
	mt.__dmc = {
		t = table_obj,
		root = autostore_singleton,
	}
	setmetatable( o, mt )

	return o
end



--====================================================================--
-- Auto Store Class
--====================================================================--

local AutoStore = {}

-- NOTE: defaults with upper case names are not copied !!!
--
AutoStore.DEFAULTS = {
	CONFIG_FILE = 'dmc_autostore.cfg',
	data_filename = { type='string', value='dmc_autostore' }, -- '.json' appended later
	timer_min = { type='integer', value=1000 },
	timer_max = { type='integer', value=4000 }
}


-- keyed on callback function
AutoStore._eventListeners = {}


-- Event Name
AutoStore.AUTOSTORE_EVENT = 'autostore_event'

-- Event Types
AutoStore.START_MIN_TIMER = 'start_min_timer'
AutoStore.STOP_MIN_TIMER = 'stop_min_timer'
AutoStore.START_MAX_TIMER = 'start_max_timer'
AutoStore.STOP_MAX_TIMER = 'stop_max_timer'
AutoStore.DATA_SAVED = 'data_saved'


function AutoStore:new()
	--print( "AutoStore:new" )
	local o = {}
	local mt = {
		__index = AutoStore
	}
	setmetatable( o, mt )

	--== Properties ==--

	-- public
	o.data = nil
	o.is_new_file = false

	-- private
	o._config = {}
	o._timer_min = nil
	o._timer_max = nil

	o._plugins = nil
	o._preSave_f = nil
	o._postRead_f = nil

	return o
end

function AutoStore:init()
	--print( "AutoStore:init" )

	STATE_ACTIVE = false
	local plugin

	-- start with DEFAULTS, cover  if something missing in config
	for k, v in pairs( AutoStore.DEFAULTS ) do
		-- if uppercase, then don't include
		if k == string.lower( k ) then
			self._config[ k ] = v.value
		end
	end

	-- read in config file
	local file_path = system.pathForFile( self.DEFAULTS.CONFIG_FILE, system.ResourceDirectory )
	local status, content = readFile( file_path, { lines=true } )

	if status == Response.SUCCESS then
		--print( "AutoStore: found config file" )
		local is_valid = true
		for _, line in ipairs( content ) do

			is_valid = ( string.find( line, '--', 1, true ) ~= 1 )

			if is_valid then
				for k, v in string.gmatch( line, "([%w_]+)%s*=%s*\'?([%w_.]+)\'?" ) do
					--print( tostring( k ) .. " = " .. tostring( v ) )

					k = string.lower( k ) -- use only lowercase inside of module
					if AutoStore.DEFAULTS[ k ] and AutoStore.DEFAULTS[ k ].type == 'integer' then
						v = tonumber( v )
						if v == nil then v = 0 end
					end
					self._config[ k ] = v
				end
			end
		end
	end


	-- container for event listeners
	self._eventListeners[ AutoStore.AUTOSTORE_EVENT ] = {}


	-- check for plugin file
	if self._config[ 'plugin_file' ] ~= nil then
		plugin = require( self._config[ 'plugin_file' ] )
		if plugin.preSaveFunction then self._preSave_f = plugin.preSaveFunction end
		if plugin.postReadFunction then self._postRead_f = plugin.postReadFunction end
		self._plugins = plugin
	end


	-- check
	-- timer_min can't be <= timer_max
	-- TODO: sanity check on timers

end


function AutoStore:load()
	--print( "AutoStore:load" )

	local file_path = system.pathForFile( self._config.data_filename .. '.json', system.DocumentsDirectory )
	local status, content = readFile( file_path, { lines=false } )
	local data

	if status == Response.ERROR then
		self.is_new_file = true
		self.data = addPixieDust( {} )
	else
		if self._postRead_f then content = self._postRead_f( content ) end
		data = json.decode( content )
		self.data = addPixieDust( data )
	end

	STATE_ACTIVE = true

end

function AutoStore:save()
	--print( "AutoStore:save" )

	local file_path = system.pathForFile( self._config.data_filename .. '.json', system.DocumentsDirectory )
	local content = json.encode( self.data:__data() )
	if self._preSave_f then content = self._preSave_f( content ) end
	local status, content = saveFile( file_path, content )

	self.is_new_file = false

	self:dispatchEvent( AutoStore.AUTOSTORE_EVENT, AutoStore.DATA_SAVED )

end

function AutoStore:isDirty()
	--print( "AutoStore:isDirty" )

	local f

	-- end any current timer
	if self._timer_min ~= nil then
		timer.cancel( self._timer_min )
		self:dispatchEvent( AutoStore.AUTOSTORE_EVENT, AutoStore.STOP_MIN_TIMER )

	end

	-- setup minimum timer
	f = function()
		if self._timer_max ~= nil then
			timer.cancel( self._timer_max )
			self:dispatchEvent( AutoStore.AUTOSTORE_EVENT, AutoStore.STOP_MAX_TIMER )
			self._timer_max = nil
		end
		self._timer_min = nil
		self:save()
	end
	self._timer_min = timer.performWithDelay( self._config.timer_min, f )
	self:dispatchEvent( AutoStore.AUTOSTORE_EVENT, AutoStore.START_MIN_TIMER, { time=self._config.timer_min } )

	-- setup maximum timer
	if self._timer_max == nil then
		f = function()
			if self._timer_min ~= nil then
				timer.cancel( self._timer_min )
				self:dispatchEvent( AutoStore.AUTOSTORE_EVENT, AutoStore.STOP_MIN_TIMER )
				self._timer_min = nil
			end
			self._timer_max = nil
			self:save()
		end
		self._timer_max = timer.performWithDelay( self._config.timer_max, f )
		self:dispatchEvent( AutoStore.AUTOSTORE_EVENT, AutoStore.START_MAX_TIMER, { time=self._config.timer_max } )
	end
end


function AutoStore:dispatchEvent( event, type, data )
	--print( "AutoStore:dispatchEvent" )

	local et = self._eventListeners[ event ]

	local e = {
		name=event,
		type=type
	}

	-- integrate the data into our custom event
	if data ~= nil then e = extend( data, e ) end

	-- dispatch out event to listeners
	for _, data in pairs( et ) do
		data[2]( e )
	end

end

function AutoStore:addEventListener( type, callback )
	--print( "AutoStore:addEventListener" )

	local o = self._eventListeners[ type ]
	if self._eventListeners[ type ] == nil then
		print( "ERROR Autostore: event type not given")
	else
		local key = tostring( callback )
		o[ key ] = { type, callback }
	end

end


if autostore_singleton == nil then
	autostore_singleton = AutoStore:new()
	autostore_singleton:init()
	autostore_singleton:load()
end
return autostore_singleton


--====================================================================--
-- dmc_corona/dmc_performance.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-performance
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
--== DMC Corona Library : DMC Performance
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.2.0"



--====================================================================--
--== Configuration


local dmc_lib_data

-- boot dmc_corona with boot script or
-- setup basic defaults if it doesn't exist
--
if false == pcall( function() require( 'dmc_corona_boot' ) end ) then
	_G.__dmc_corona = {
		dmc_corona={},
	}
end

dmc_lib_data = _G.__dmc_corona




--====================================================================--
--== DMC Performance
--====================================================================--


--====================================================================--
--== Configuration


dmc_lib_data.dmc_performance = dmc_lib_data.dmc_performance or {}

local DMC_PERFORMANCE_DEFAULTS = {
	output_markers = true,
	memory_active = false
}

local dmc_performance_data = {}
for k,v in pairs( DMC_PERFORMANCE_DEFAULTS ) do dmc_performance_data[k] = v end
for k,v in pairs( dmc_lib_data.dmc_performance ) do dmc_performance_data[k] = v end



--====================================================================--
--== Imports


-- none



--====================================================================--
--== Setup, Constants


local collectgarbage = collectgarbage
local mabs, mfloor = math.abs, math.floor
local sysinfo, systimer = system.getInfo, system.getTimer
local sformat = string.format
local tcancel, tdelay = timer.cancel, timer.performWithDelay
local tonumber, tostring, type = tonumber, tostring, type

local Perf = {}
Perf.VERSION = VERSION

local firstTimeMarker = nil
local lastTimeMarker = nil
local timeMarks = {}
local memoryWatcherCallback = nil



--====================================================================--
--== Support Functions


-- castValue()
-- config values come as booleans or numbers (with a :BOOL or :INT
-- type) or as strings (without one)
--
local function castValue( v )
	if type(v)=='boolean' or type(v)=='number' then return v end
	if v=='true' then return true end
	if v=='false' then return false end
	return tonumber( v )
end

-- toBool()
-- anything but false (or 'false') is on
--
local function toBool( v )
	return castValue( v ) ~= false
end


local function markerOutput( str, params )
	params = params or {}
	if params.prefix==nil then params.prefix="MARK    " end
	print( sformat( "%s: %s", params.prefix, str ) )
end



--====================================================================--
-- Performance Module
--====================================================================--


--======================================================--
-- Time Marker

function Perf.markTime( marker, params )
	params = params or {}
	if params.reset==true then lastTimeMarker = nil end
	if params.print==nil then params.print = true end
	--==--
	local t = systimer()
	local precision = 100000
	local delta = 0
	local name = marker==nil and '(unnamed)' or tostring( marker )

	if firstTimeMarker==nil and dmc_performance_data.output_markers then
		markerOutput( sformat( "Application Started:  (T:%s)", tostring(t) ) )
		firstTimeMarker = t
	end
	if lastTimeMarker==nil then lastTimeMarker = t end

	if params.print and dmc_performance_data.output_markers then
		delta = mfloor((t-lastTimeMarker)*precision)/precision
		markerOutput( sformat( "%s:  %s  (T:%s)", name, tostring(delta), tostring(t) ) )
	end

	lastTimeMarker = t
	if marker then timeMarks[ marker ] = t end
end

function Perf.markTimeDiff( marker1, marker2 )
	local precision = 100000
	local t1, t2 = timeMarks[marker1], timeMarks[marker2]
	if t1==nil or t2==nil then
		print( sformat( "WARNING: dmc_performance: markTimeDiff(): no marker named '%s'", tostring( t1==nil and marker1 or marker2 ) ) )
		return
	end
	local delta = mabs( mfloor((t1-t2 )*precision)/precision )

	if dmc_performance_data.output_markers then
		markerOutput( sformat( "%s <=> %s  <d> %s", tostring(marker1), tostring(marker2), tostring(delta) ), {prefix="MARK <d>"} )
	end
	return delta
end



--======================================================--
-- Memory Monitor


-- Memory Monitor function

function Perf.memoryMonitor( param )
	collectgarbage()
	local memory = collectgarbage( 'count' )
	local texture = sysinfo( 'textureMemoryUsed' ) / 1048576

	if type(param)=='string' then print(param) end
	print( sformat( "M: %s  T: %s", tostring(memory), tostring(texture) ) )
end


-- watchMemory()
-- prints out current memory values
--
-- value (boolean:
-- if true, start memory watching every frame
-- if false, stop current memory watching
-- if number, start memory watching every Number of milliseconds
--
function Perf.watchMemory( value )
	-- print( "Perf.watchMemory", value )

	-- one watch at a time: a new one replaces the old
	if memoryWatcherCallback ~= nil then memoryWatcherCallback() end

	if value==true then
		-- setup constant, frame rate memory watch

		Runtime:addEventListener( 'enterFrame', Perf.memoryMonitor )

		memoryWatcherCallback = function()
			Runtime:removeEventListener( 'enterFrame', Perf.memoryMonitor )
			memoryWatcherCallback = nil
		end

	elseif type(value)=='number' and value > 0 then

		local memTimer = tdelay( value, Perf.memoryMonitor, 0 )

		memoryWatcherCallback = function()
			tcancel( memTimer )
			memoryWatcherCallback = nil
		end

	end

end


dmc_performance_data.output_markers = toBool( dmc_performance_data.output_markers )
dmc_performance_data.memory_active = castValue( dmc_performance_data.memory_active )

if dmc_performance_data.memory_active then
	Perf.watchMemory( dmc_performance_data.memory_active )
end




return Perf

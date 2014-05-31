--====================================================================--
-- dmc_performance.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_performance.lua
--====================================================================--

--[[

Copyright (C) 2011-2013 David McCuskey. All Rights Reserved.

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
-- DMC Corona Library : DMC Performance
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
-- DMC Performance
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_performance = dmc_lib_data.dmc_performance or {}

local DMC_PERFORMANCE_DEFAULTS = {
	memory_active = 'false'
}

local dmc_performance_data = Utils.extend( dmc_lib_data.dmc_performance, DMC_PERFORMANCE_DEFAULTS )


--====================================================================--
-- Setup, Constants

local Perf = {}


--====================================================================--
-- Support Methods

local function castValue( v )
	local ret = nil

	if v == 'true' then
		ret = true
	elseif v == 'false' then
		ret = false
	else
		ret = tonumber( v )
	end

	return ret
end



--====================================================================--
-- Performance Module
--====================================================================--


--====================================================================--
--== Time Marker ==--

local firstTimeMarker = nil
local lastTimeMarker = nil
local timeMarks = {}

local function calculateTime()

end
function Perf.markTime( marker, params )
	local t = system.getTimer()
	local precision = 100000
	local delta = 0
	params = params or {}
	if params.reset == true then lastTimeMarker = nil end
	if params.print == nil then params.print = true end

	if firstTimeMarker == nil then
		print( "MARK    : ".."Application Started: ".." (T:"..tostring(t)..")" )
		firstTimeMarker = t
	end
	if lastTimeMarker == nil then lastTimeMarker = t end

	if params.print then
		delta = math.floor((t-lastTimeMarker)*precision)/precision
		print( "MARK    : "..marker, tostring(delta).." (T:"..tostring(t)..")" )
	end

	lastTimeMarker = t
	if marker then timeMarks[ marker ] = t end
end

function Perf.markTimeDiff( marker1, marker2 )
	local precision = 100000
	local t1, t2 = timeMarks[marker1], timeMarks[marker2]
	local delta = math.floor((t1-t2 )*precision)/precision

	print( "MARK <d>: ".. marker1.."<=>"..marker2.." <d> ".. tostring( math.abs(delta)) )
end


--====================================================================--
--== Memory Monitor ==--

local memoryWatcherCallback = nil

-- Memory Monitor function

function Perf.memoryMonitor()

	collectgarbage()

	local memory = collectgarbage("count")
	local texture = system.getInfo( "textureMemoryUsed" ) / 1048576

	print( "M: " .. memory, " T: " .. texture )

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
	print( "Perf.watchMemory", value )
	local f

	if value == true then
		-- setup constant, frame rate memory watch

		Runtime:addEventListener( "enterFrame", Perf.memoryMonitor )

		memoryWatcherCallback = function()
			Runtime:removeEventListener( "enterFrame", Perf.memoryMonitor )
			memoryWatcherCallback = nil
		end

	elseif type( value ) == "number" and value > 0 then

		local timer = timer.performWithDelay( value, Perf.memoryMonitor, 0 )

		memoryWatcherCallback = function()
			timer.cancel( timer )
			memoryWatcherCallback = nil
		end

	elseif value == false and memoryWatcherCallback ~= nil then
		-- stop watching memory
		memoryWatcherCallback()
	end

end


if dmc_performance_data.memory_active then
	dmc_performance_data.memory_active = castValue( dmc_performance_data.memory_active )
	Perf.watchMemory( dmc_performance_data.memory_active )
end




return Perf

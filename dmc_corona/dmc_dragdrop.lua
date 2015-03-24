--====================================================================--
-- dmc_corona/dmc_dragdrop.lua
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
-- DMC Corona Library : DMC Drag Drop
--====================================================================--


-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.5.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


--====================================================================--
--== Support Functions


local Utils = {} -- make copying from dmc_utils easier


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
--== DMC Drag Drop
--====================================================================--



--====================================================================--
--== Configuration


dmc_lib_data.dmc_dragdrop = dmc_lib_data.dmc_dragdrop or {}

local DMC_DRAGDROP_DEFAULTS = {
	debug_active=false,
}

local dmc_dragdrop_data = Utils.extend( dmc_lib_data.dmc_dragdrop, DMC_DRAGDROP_DEFAULTS )



--====================================================================--
--== Imports


local Objects = require 'dmc_objects'



--====================================================================--
--== Setup, Constants


local tinsert = table.insert
local tremove = table.remove

-- setup some aliases to make code cleaner
local newClass = Objects.newClass
local Class = Objects.Class

local CORONA_META = getmetatable( display.getCurrentStage() )

local COLOR_BLUE = { 25/255, 100/255, 255/255 }
local COLOR_LIGHTBLUE = { 90/255, 170/255, 255/255 }
local COLOR_GREEN = { 50/255, 255/255, 50/255 }
local COLOR_LIGHTGREEN = { 170/255, 225/255, 170/255 }
local COLOR_RED = { 255/255, 50/255, 50/255 }
local COLOR_LIGHTRED = { 255/255, 120/255, 120/255 }
local COLOR_GREY = { 180/255, 180/255, 180/255 }
local COLOR_LIGHTGREY = { 200/255, 200/255, 200/255 }


local DragSingleton = nil



--====================================================================--
--== Support Functions


-- createProxySquare()
--
-- function to help create shapes, useful for drag/drop target examples
--
local function createProxySquare( params )
	params = params or {}
	assert( type(params)=='table', "createProxySquare requires params" )
	assert( params.height and params.width, "createProxySquare requires height and width" )
	if params.fillColor==nil then params.fillColor=COLOR_LIGHTGREY end
	if params.strokeColor==nil then params.strokeColor=COLOR_GREY end
	if params.strokeWidth==nil then params.strokeWidth=3 end
	--==--
	local o = display.newRect(0, 0, params.width, params.height )
	o.strokeWidth = params.strokeWidth
	o:setFillColor( unpack( params.fillColor ) )
	o:setStrokeColor( unpack( params.strokeColor ) )
	return o
end


-- is_display_object
--
-- test whether object is Corona display object
-- Returns true for any object returned from display.new*().
-- note that all Corona types seem to share the same metatable...
--
local function is_display_object( o )
	return ( type(o)=='table' and getmetatable(o)==CORONA_META )
end



--====================================================================--
--== Drag Drop Class
--====================================================================--


local DragDrop = newClass( Class, {name="Drag Drop"} )

--== Class Constants

-- property name holding Corona display object
-- eg, for objects from dmc-objects
--
DragDrop.DISPLAY_PROPERTY = 'view'

DragDrop.ANIMATE_TIME_SLOW = 300
DragDrop.ANIMATE_TIME_FAST = 100

DragDrop.COLOR_BLUE = COLOR_BLUE
DragDrop.COLOR_LIGHTBLUE = COLOR_LIGHTBLUE
DragDrop.COLOR_GREEN = COLOR_GREEN
DragDrop.COLOR_LIGHTGREEN = COLOR_LIGHTGREEN
DragDrop.COLOR_RED = COLOR_RED
DragDrop.COLOR_LIGHTRED = COLOR_LIGHTRED
DragDrop.COLOR_GREY = COLOR_GREY
DragDrop.COLOR_LIGHTGREY = COLOR_LIGHTGREY


--== Event Constants

DragDrop.EVENT = 'drag-drop-event'


--======================================================--
-- Start: Setup Lua Objects

function DragDrop:__new__( ... )
	-- print( "DragDrop:__new__" )

	--== Create Properties

	self._display_property = self.DISPLAY_PROPERTY

	self._proxy_color = {}
	self._proxy_stroke_color = color_lightgrey

	-- hash of all registered objects
	-- hashed on object string
	self._registered = {}

	-- list of registered objects with dragStart()
	self._onDragStartList = {}

	-- list of registered objects with dragStop()
	self._onDragStopList = {}

	-- Drag Targets Info
	-- a hash, indexed by drag target source
	self._drag_targets = {}

	-- Drag Target Event Info
	-- drop_target: target being dropped on, Display Object
	-- drop_target_accept: drag event is accepted, Boolean
	self._drop_target = nil
	self._drop_target_accept = false

end

-- function DragDrop:__destroy__()
-- 	print( "DragDrop:__destroy__" )
-- end


-- End: Setup Lua Objects
--======================================================--




--====================================================================--
--== Public Methods


-- setDisplayProperty
--
-- sets the property name holding Corona display object
--
function DragDrop.__setters:display_name( value )
	-- print( "DragDrop.__setters:display_name", value )
	assert( type(value)=='string', "fdsfsd")
	--==--
	self._display_property = value
end


-- register()
--
-- register a Drop Target
-- @param drop, Corona Display Object
-- @param params, table with parameters
--
function DragDrop:register( drop, params )
	-- print( "DragDrop:register", drop )
	assert( drop, "DragDrop:register requires drop target" )
	assert( params==nil or type(params)=='table', "DragDrop:register incorrect type for register params" )
	--==--

	--== create our data structure for the object

	--[[
		call_with_object: whether to call using obj/functions, boolean
		dragStart: drag event callback, function
		dragEnter: drag event callback, function
		dragOver: drag event callback, function
		dragDrop: drag event callback, function
		dragExit: drag event callback, function
		dragStop: drag event callback, function
	--]]
	local ds = {}

	local tmp
	if params==nil then
		ds.call_with_object = true
		tmp = drop
	else
		ds.call_with_object = false
		tmp = params
	end

	-- save callbacks
	ds.dragStart = tmp.dragStart or nil
	ds.dragEnter = tmp.dragEnter or nil
	ds.dragOver = tmp.dragOver or nil
	ds.dragDrop = tmp.dragDrop or nil
	ds.dragExit = tmp.dragExit or nil
	ds.dragStop = tmp.dragStop or nil

	-- save drop information
	self._registered[ drop ] = ds

	-- save for lookup optimization
	if ds.dragStart then
		tinsert( self._onDragStartList, drop )
	end
	if ds.dragStop then
		tinsert( self._onDragStopList, drop )
	end
end


function DragDrop:unregister( drop )
	-- print( "DragDrop:unregister", drop )
	assert( drop, "DragDrop:unregister requires drop target" )
	--==--

	local idx, list

	self._registered[ drop ] = nil

	idx, list = nil, self._onDragStartList
	for i, item in ipairs( list ) do
		if item==drop then idx=i; break end
	end
	if idx~=nil then tremove( list, idx ) end

	idx, list = nil, self._onDragStopList
	for i, item in ipairs( list ) do
		if item==drop then idx=i; break end
	end
	if idx~=nil then tremove( list, idx ) end

end


-- doDrag()
--
-- tell about a drag event
-- @param obj, Corona Display Object
-- @param params, table with parameters
--
function DragDrop:doDrag( drag_orgin, event, drag_op_info )
	-- print( "DragDrop:doDrag", drag_orgin )
	assert( drag_orgin, "DragDrop:doDrag requires origin target" )
	assert( event, "DragDrop:doDrag requires touch event" )
	assert( drag_op_info==nil or type(drag_op_info)=='table', "DragDrop:doDrag incorrect type for register params" )
	drag_op_info = drag_op_info or {}
	--==--

	local drag_proxy
	if drag_op_info.proxy then
		drag_proxy=drag_op_info.proxy
	else
		drag_proxy = createProxySquare{
			width=drag_orgin.width,
			height=drag_orgin.height,
			fillColor=self._proxy_fillColor,
			strokeColor=self._proxy_strokeColor,
			strokeWidth=self._proxy_strokeWidth
		}
	end

	--== Create data structure for this drag operation

	--[[
		proxy: dragged item, Display Object / dmc_object
		origin: dragged item origin object, Dislay Object
		format: dragged item data format, String
		data: any data to be sent around, <any>
		x_offset: dragged item x-offset from touch center, Integer
		y_offset: dragged item y-offset from touch center, Integer
		alpha: dragged item alpha, Number
	--]]
	local drag_info = {}

	drag_info.proxy = drag_proxy
	drag_info.origin = drag_orgin
	drag_info.format = drag_op_info.format
	drag_info.data = drag_op_info.data
	drag_info.x_offset = drag_op_info.xOffset or 0
	drag_info.y_offset = drag_op_info.yOffset or 0
	drag_info.alpha = drag_op_info.alpha or 0.5

	self._drag_targets[ drag_proxy ] = drag_info

	--== Update the Drag Target visual item

	drag_proxy.x = event.x + drag_info.x_offset
	drag_proxy.y = event.y + drag_info.y_offset
	drag_proxy.alpha = drag_info.alpha

	--== Start our drag operation

	self:_startListening( drag_proxy )
	self:_doDragStart( drag_proxy )

end


-- acceptDragDrop()
--
-- notify manager about drag accept
--
function DragDrop:acceptDragDrop()
	self._drop_target_accept = true
end



--====================================================================--
--== Private Methods


-- _createEventStructure()
--
-- create generic event structure to send out
-- @param obj, drop targets
--
function DragDrop:_createEventStructure( obj, drag_info )
	assert( obj, "DragDrop:_createEventStructure requires object" )
	--==--
	local drag_info = drag_info or {}
	local evt = {
		name=self.EVENT,
		target=obj,
		format=drag_info.format,
		data = drag_info.data,
	}
	return evt
end


-- _doDragStart()
--
-- start a drag process
-- @param drag_proxy, the drag proxy object
--
function DragDrop:_doDragStart( drag_proxy )
	-- print( "DragDrop:_doDragStart", drag_proxy )
	assert( drag_proxy, "DragDrop:_doDragStart requires drag proxy" )
	--==--
	drag_proxy.__is_dmc_drag = true
	display.getCurrentStage():setFocus( drag_proxy )

	local drag_info = self._drag_targets[ drag_proxy ]
	local onDragStartList = self._onDragStartList
	for i=1, #onDragStartList do

		local o = onDragStartList[ i ]
		local ds = self._registered[ o ]
		local e = self:_createEventStructure( o, drag_info )

		if ds.call_with_object then
			ds.dragStart( o, e )
		else
			ds.dragStart( e )
		end
	end
end


-- _doDragStop()
--
-- stop a drag process
-- @param drag_proxy, the drag proxy object
--
function DragDrop:_doDragStop( drag_proxy )
	assert( drag_proxy, "DragDrop:_doDragStart requires drag proxy" )
	--==--
	drag_proxy.__is_dmc_drag = nil
	display.getCurrentStage():setFocus( nil )

	local drag_info = self._drag_targets[ drag_proxy ]
	local onDragStartList = self._onDragStopList
	for i=1, #onDragStartList do

		local o = onDragStartList[ i ]
		local ds = self._registered[ o ]
		local e = self:_createEventStructure( o, drag_info )

		if ds.call_with_object then
			ds.dragStop( o, e )
		else
			ds.dragStop( e )
		end
	end
end



-- _createEndAnimation()
--
-- stop a drag process
-- @param params, table of animation parameters
-- x, number coordinate
-- y, number coordinate
-- time, milliseconds
-- resize, boolean
-- drag_proxy, the drag proxy pbject
function DragDrop:_createEndAnimation( params )
	assert( type(params)=='table', "_createEndAnimation wrong type for params" )
	assert( params.drag_proxy, "_createEndAnimation missing param 'drag_proxy'" )
	params.time = params.time or self.ANIMATE_TIME_SLOW
	--==--

	local removeFunc, tParams, doFunc

	-- function to remove proxy

	removeFunc = function( e )
		local dp = params.drag_proxy
		self._drag_targets[ dp ] = nil
		if dp.removeSelf then dp:removeSelf() end
	end

	-- params to move and/or scale the proxy

	local tParams = {
		onComplete=removeFunc,
		time=params.time,
		x=params.x,
		y=params.y,
	}
	if params.resize then
		tParams.width = 10 ; tParams.height = 10
	end

	-- transition function

	doFunc = function( ... )
		transition.to( params.drag_proxy, tParams )
	end

	return doFunc
end


-- _startListening()
--
-- setup event listener on drag proxy
--
function DragDrop:_startListening( drag_proxy )
	assert( drag_proxy, "DragDrop:_startListening requires drag proxy" )
	--==--
	local drag_info = self._drag_targets[ drag_proxy ]
	drag_info.proxy:addEventListener( 'touch', self )
end

-- _stopListening()
--
-- remove event listener on drag proxy
--
function DragDrop:_stopListening( drag_proxy )
	assert( drag_proxy, "DragDrop:_stopListening requires drag proxy" )
	--==--
	local drag_info = self._drag_targets[ drag_proxy ]
	drag_info.proxy:removeEventListener( 'touch', self )
end


-- _searchDropTargets()
--
-- look through drop targets and see if any bound our location
-- find and return first hit
--
function DragDrop:_searchDropTargets( x, y )
	assert( x and y, "DragDrop:_searchDropTargets requires x and y params" )
	--==--
	local target = nil

	for drop, _ in pairs( self._registered ) do
		local o = drop

		if not is_display_object( drop ) then
			o = drop[ self._display_property ]
			if o == nil then
				print( string.format( "\nWARNING: object not of type Corona Display nor does it have display property '%s'\n", self._display_property ) )
			end
		end

		local bounds, isWithinBounds

		bounds = o.contentBounds
		isWithinBounds =
			( bounds.xMin <= x and bounds.xMax >= x and
			bounds.yMin <= y and bounds.yMax >= y )

		if isWithinBounds then target=drop; break end

	end

	return target
end




--====================================================================--
--== Event Handlers


function DragDrop:touch( e )

	local proxy = e.target
	local phase = e.phase
	local result = false

	if not proxy.__is_dmc_drag then return result end

	local drag_info = self._drag_targets[ proxy ]

	if phase=='began' then
		return result

	elseif phase=='moved' then

		-- keep the dragged item moving with the touch coordinates
		proxy.x = e.x + drag_info.x_offset
		proxy.y = e.y + drag_info.y_offset

		-- see if we are over any drop targets
		local newDropTarget = self:_searchDropTargets( e.x, e.y )

		if self._drop_target == newDropTarget then
			-- over the same object, so call dragOver()

			if self._drop_target and self._drop_target_accept then

				local o = newDropTarget
				local ds = self._registered[ o ]
				local f = ds.dragOver
				if f then
					local e = self:_createEventStructure( o, drag_info )
					if ds.call_with_object then
						result = f( o, e )
					else
						result = f( e )
					end
				end
			end

		elseif self._drop_target ~= newDropTarget then
			-- new target is different
			-- we exited current, so call dragExit() on current

			if self._drop_target and self._drop_target_accept then

				local o = self._drop_target
				local ds = self._registered[ o ]
				local f = ds.dragExit
				if f then
					local e = self:_createEventStructure( o, drag_info )
					if ds.call_with_object then
						result = f( o, e )
					else
						result = f( e )
					end
				end
			end

			self._drop_target_accept = false

			--== call dragEnter on newDropTarget

			if newDropTarget then
				local o = newDropTarget
				local ds = self._registered[ o ]
				local f = ds.dragEnter
				if f then
					local e = self:_createEventStructure( o, drag_info )
					if ds.call_with_object then
						result = f( o, e )
					else
						result = f( e )
					end
				end
			end

		end

		-- save current drop target
		self._drop_target = newDropTarget


	elseif phase=='ended' or phase=='cancelled' then

		local animateFunc

		if self._drop_target and self._drop_target_accept then
			-- same object, so call dragDrop()

			local o = self._drop_target
			local ds = self._registered[ o ]
			local f = ds.dragDrop
			if f then
				local e = self:_createEventStructure( o, drag_info )

				if ds.call_with_object then
					result = f( o, e )
				else
					result = f( e )
				end
			end
			-- drag accepted, so keep on Drop Target and scale
			animateFunc = self:_createEndAnimation{
				x=o.x, y=o.y,
				time=DragDrop.ANIMATE_TIME_FAST,
				resize=true, drag_proxy=proxy
			}

		else
			-- drop not accepted, so move proxy back to drag origin
			animateFunc = self:_createEndAnimation{
				x=drag_info.origin.x, y=drag_info.origin.y,
				time=DragDrop.ANIMATE_TIME_SLOW,
				resize=false, drag_proxy=proxy
			}

		end

		self._drop_target = nil
		self._drop_target_accept = false

		self:_doDragStop( proxy )
		self:_stopListening( proxy )

		animateFunc()

	end

	return result
end



--====================================================================--
--== Drag Drop Singleton
--====================================================================--


DragSingleton = DragDrop:new()

return DragSingleton

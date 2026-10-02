--====================================================================--
-- dmc_corona/dmc_dragdrop.lua
--
-- Documentation: https://github.com/dmccuskey/dmc-dragdrop
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

local VERSION = "0.6.0"



--====================================================================--
-- DMC Corona Library Config
--====================================================================--


-- boot dmc_corona with boot script, if it's there
-- dmc-dragdrop has no settings
--
pcall( function() require( 'dmc_corona_boot' ) end )



--====================================================================--
--== DMC Drag Drop
--====================================================================--



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


-- contentCenter()
--
-- centre of a display object, in content coordinates
-- returns nil if it has no bounds (eg, it has been removed)
--
local function contentCenter( o )
	local bounds = o and o.contentBounds
	if not bounds then return nil end
	return ( bounds.xMin+bounds.xMax )/2, ( bounds.yMin+bounds.yMax )/2
end


-- toParent()
--
-- convert content coordinates to those of an object's parent
--
local function toParent( o, x, y )
	if o.parent then x, y = o.parent:contentToLocal( x, y ) end
	return x, y
end


-- copyList()
--
-- copy of a list, so a callback can change the original
-- while we go through it
--
local function copyList( list )
	local copy = {}
	for i=1, #list do copy[i] = list[i] end
	return copy
end


-- removeFromList()
--
local function removeFromList( list, item )
	for i=#list, 1, -1 do
		if list[i]==item then tremove( list, i ) end
	end
end



--====================================================================--
--== Drag Drop Class
--====================================================================--


local DragDrop = newClass( Class, {name="Drag Drop"} )

DragDrop.VERSION = VERSION

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

	-- hash of all registered objects
	-- hashed on object string
	self._registered = {}

	-- list of registered objects with dragStart()
	self._onDragStartList = {}

	-- list of registered objects with dragStop()
	self._onDragStopList = {}

	-- Drag Info, one per drag
	-- a hash, indexed by drag proxy
	self._drag_targets = {}

	-- Drag Info of the drag whose event is being sent,
	-- for acceptDragDrop()
	self._dispatch_drag = nil

	-- drop targets already warned about, having no display object
	self._warned = setmetatable( {}, { __mode='k' } )

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
	assert( type(value)=='string', "DragDrop.display_name must be a string" )
	--==--
	self._display_property = value
end


-- register()
--
-- register a Drop Target
-- registering it again replaces its handlers
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
	removeFromList( self._onDragStartList, drop )
	removeFromList( self._onDragStopList, drop )
	if ds.dragStart then
		tinsert( self._onDragStartList, drop )
	end
	if ds.dragStop then
		tinsert( self._onDragStopList, drop )
	end
end


-- unregister()
--
-- a drag over the target carries on as if over nothing
--
function DragDrop:unregister( drop )
	-- print( "DragDrop:unregister", drop )
	assert( drop, "DragDrop:unregister requires drop target" )
	--==--

	self._registered[ drop ] = nil
	removeFromList( self._onDragStartList, drop )
	removeFromList( self._onDragStopList, drop )

	for _, drag_info in pairs( self._drag_targets ) do
		if drag_info.drop_target==drop then
			drag_info.drop_target = nil
			drag_info.drop_target_accept = false
		end
	end

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
			fillColor=drag_op_info.fillColor,
			strokeColor=drag_op_info.strokeColor,
			strokeWidth=drag_op_info.strokeWidth
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
		touch_id: id of the touch doing the drag
		drop_target: target being dropped on, Display Object
		drop_target_accept: drag event is accepted, Boolean
	--]]
	local drag_info = {}

	drag_info.proxy = drag_proxy
	drag_info.origin = drag_orgin
	drag_info.format = drag_op_info.format
	drag_info.data = drag_op_info.data
	drag_info.x_offset = drag_op_info.xOffset or 0
	drag_info.y_offset = drag_op_info.yOffset or 0
	drag_info.alpha = drag_op_info.alpha or 0.5
	drag_info.touch_id = event.id
	drag_info.drop_target = nil
	drag_info.drop_target_accept = false

	self._drag_targets[ drag_proxy ] = drag_info

	--== Update the Drag Target visual item

	self:_moveProxy( drag_info, event.x, event.y )
	drag_proxy.alpha = drag_info.alpha

	--== Start our drag operation

	self:_startListening( drag_proxy )
	self:_doDragStart( drag_proxy )

end


-- acceptDragDrop()
--
-- notify manager about drag accept
-- applies to the drag whose event is being sent
--
function DragDrop:acceptDragDrop()
	local drag_info = self._dispatch_drag
	if drag_info then drag_info.drop_target_accept = true end
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


-- _dispatch()
--
-- call a drop target's handler for an event, if it has one
-- @param name, handler name, eg 'dragEnter'
-- @param o, drop target
-- @param drag_info, the drag
--
function DragDrop:_dispatch( name, o, drag_info )
	local ds = self._registered[ o ]
	local f = ds and ds[ name ]
	if not f then return end

	local e = self:_createEventStructure( o, drag_info )
	local prev = self._dispatch_drag
	self._dispatch_drag = drag_info
	if ds.call_with_object then
		f( o, e )
	else
		f( e )
	end
	self._dispatch_drag = prev
end


-- _getDisplayObject()
--
-- a target's display object, the target itself or its display property
--
function DragDrop:_getDisplayObject( o )
	if is_display_object( o ) then return o end
	return o[ self._display_property ]
end


-- _setFocus()
--
-- give the proxy the touch focus, or take it away
-- under multitouch, the touch id gives each drag its own focus;
-- without, Solar2D treats it as the one focus
--
function DragDrop:_setFocus( drag_info, focus )
	local stage = display.getCurrentStage()
	local proxy = drag_info.proxy
	if drag_info.touch_id==nil then
		stage:setFocus( focus and proxy or nil )
	elseif focus then
		stage:setFocus( proxy, drag_info.touch_id )
	else
		stage:setFocus( proxy, nil )
	end
end


-- _moveProxy()
--
-- put the proxy at a touch point, in content coordinates
--
function DragDrop:_moveProxy( drag_info, x, y )
	local proxy = drag_info.proxy
	proxy.x, proxy.y = toParent( proxy, x + drag_info.x_offset, y + drag_info.y_offset )
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
	local drag_info = self._drag_targets[ drag_proxy ]

	drag_proxy.__is_dmc_drag = true
	self:_setFocus( drag_info, true )

	local list = copyList( self._onDragStartList )
	for i=1, #list do
		self:_dispatch( 'dragStart', list[ i ], drag_info )
	end
end


-- _doDragStop()
--
-- stop a drag process
-- @param drag_proxy, the drag proxy object
--
function DragDrop:_doDragStop( drag_proxy )
	assert( drag_proxy, "DragDrop:_doDragStop requires drag proxy" )
	--==--
	local drag_info = self._drag_targets[ drag_proxy ]

	drag_proxy.__is_dmc_drag = nil
	self:_setFocus( drag_info, false )

	local list = copyList( self._onDragStopList )
	for i=1, #list do
		self:_dispatch( 'dragStop', list[ i ], drag_info )
	end
end



-- _createEndAnimation()
--
-- stop a drag process
-- @param params, table of animation parameters
-- x, number content coordinate
-- y, number content coordinate
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
	}
	if params.x and params.y then
		tParams.x, tParams.y = toParent( params.drag_proxy, params.x, params.y )
	end
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
		local o = self:_getDisplayObject( drop )
		local bounds = o and o.contentBounds

		if o == nil and not self._warned[ drop ] then
			self._warned[ drop ] = true
			print( string.format( "\nWARNING: object not of type Corona Display nor does it have display property '%s'\n", self._display_property ) )
		end

		if bounds and
			bounds.xMin <= x and bounds.xMax >= x and
			bounds.yMin <= y and bounds.yMax >= y then
			target=drop; break
		end

	end

	return target
end




--====================================================================--
--== Event Handlers


function DragDrop:touch( e )

	local proxy = e.target
	local phase = e.phase
	local drag_info = self._drag_targets[ proxy ]

	if not proxy.__is_dmc_drag or not drag_info then return false end

	if phase=='began' then
		return false

	elseif phase=='moved' then

		-- keep the dragged item moving with the touch coordinates
		self:_moveProxy( drag_info, e.x, e.y )

		-- see if we are over any drop targets
		local dropTarget = drag_info.drop_target
		local newDropTarget = self:_searchDropTargets( e.x, e.y )

		if dropTarget == newDropTarget then
			-- over the same object, so call dragOver()

			if dropTarget and drag_info.drop_target_accept then
				self:_dispatch( 'dragOver', dropTarget, drag_info )
			end

		else
			-- new target is different
			-- we exited current, so call dragExit() on current

			if dropTarget and drag_info.drop_target_accept then
				self:_dispatch( 'dragExit', dropTarget, drag_info )
			end

			-- save current drop target, before dragEnter()
			-- so an unregister() there clears it
			drag_info.drop_target = newDropTarget
			drag_info.drop_target_accept = false

			--== call dragEnter on newDropTarget

			if newDropTarget then
				self:_dispatch( 'dragEnter', newDropTarget, drag_info )
			end

		end


	elseif phase=='ended' or phase=='cancelled' then

		local dropTarget = drag_info.drop_target
		local animateFunc

		if dropTarget and drag_info.drop_target_accept then
			-- drag accepted, so keep on Drop Target and scale
			-- (find where before dragDrop(), which may remove it)
			local x, y = contentCenter( self:_getDisplayObject( dropTarget ) )
			animateFunc = self:_createEndAnimation{
				x=x, y=y,
				time=self.ANIMATE_TIME_FAST,
				resize=true, drag_proxy=proxy
			}

			-- same object, so call dragDrop()
			self:_dispatch( 'dragDrop', dropTarget, drag_info )

		else
			-- drop not accepted, so move proxy back to drag origin
			local x, y = contentCenter( self:_getDisplayObject( drag_info.origin ) )
			animateFunc = self:_createEndAnimation{
				x=x, y=y,
				time=self.ANIMATE_TIME_SLOW,
				resize=false, drag_proxy=proxy
			}

		end

		drag_info.drop_target = nil
		drag_info.drop_target_accept = false

		self:_doDragStop( proxy )
		self:_stopListening( proxy )

		animateFunc()

	end

	return true
end



--====================================================================--
--== Drag Drop Singleton
--====================================================================--


DragSingleton = DragDrop:new()

return DragSingleton

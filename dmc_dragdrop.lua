
--====================================================================--
-- dmc_dragdrop.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_dragdrop.lua
--====================================================================--

--[[

Copyright (C) 2011 David McCuskey. All Rights Reserved.

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


-- =========================================================
-- Imports
-- =========================================================

-- import DMC Objects file
local Objects = require( "dmc_objects" )

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local Object = Objects.Object



local coronaMetaTable = getmetatable( display.getCurrentStage() )

--- Returns true for any object returned from display.new*().
-- note that all Corona types seem to share the same metatable...
local isDisplayObject = function( object )
	return type( object ) == "table" and getmetatable( object ) == coronaMetaTable
end



--====================================================================--
-- Drag Drop class
--====================================================================--

local DragDrop = inheritsFrom( Object )
DragDrop.NAME = "Drag Drop"

DragDrop._registered = {}	-- hash of all registered objects
DragDrop._onDragStart = {}	-- list of registered objects with dragStart()
DragDrop._onDragStop = {}	-- list of registered objects with dragStop()

-- property name holding Corona display object
DragDrop.DISPLAY_PROPERTY = "display"

DragDrop.ANIMATE_TIME_SLOW = 300
DragDrop.ANIMATE_TIME_FAST = 100


-- Drag Targets Info
-- a hash, indexed by drag target source
DragDrop._drag_targets = {}

-- Drop Target Info
-- drop_target: object being dropped on, Display Object
-- drop_target: dropped point is selected, Boolean
DragDrop.drop_target = nil
DragDrop.drop_target_accept = false


function DragDrop:setDisplayProperty( name )
	DragDrop.DISPLAY_PROPERTY = name
end

function DragDrop:register( obj, params )

	-- create our storage data structure for the object
	local ds = {}
	ds.obj = obj
	ds.call_with_object = false 	-- whether we call using object
	if not params then
		ds.call_with_object = true
		t = obj
	else
		ds.call_with_object = false
		t = params
	end

	ds.dragStart = t.dragStart or nil
	ds.dragEnter = t.dragEnter or nil
	ds.dragOver = t.dragOver or nil
	ds.dragDrop = t.dragDrop or nil
	ds.dragExit = t.dragExit or nil
	ds.dragStop = t.dragStop or nil

	self._registered[ obj ] = ds

	-- save for lookup optimization
	if ds.dragStart then
		table.insert( self._onDragStart, obj )
	end
	if ds.dragStop then
		table.insert( self._onDragStop, obj )
	end
end

function DragDrop:doDrag( drag_source, format, event, drag_target_info )

	--== process Drag Target Info params

	local drag_target_info = drag_target_info or {}
	local drag_target = drag_target_info.target;


	--== Create data structure for this drag operation

	--[[
		source: dragged item, Display Object / dmc_object
		origin: dragged item origin object, Dislay Object
		format: dragged item data format, String
		x_offset: dragged item x-offset from touch center, Integer
		y_offset: dragged item y-offset from touch center, Integer
		alpha: dragged item alpha, Number
	--]]
	local drag_info = {}

	drag_info.source = drag_target
	drag_info.origin = drag_source
	drag_info.format = format
	drag_info.x_offset = drag_target_info.xOffset or 0
	drag_info.y_offset = drag_target_info.yOffset or 0
	drag_info.alpha = drag_target_info.alpha or 0.5

	DragDrop._drag_targets[ drag_target ] = drag_info


	--== Update the Drag Target visual item

	drag_target.x = event.x + drag_info.x_offset
	drag_target.y = event.y + drag_info.y_offset
	drag_target.alpha = drag_info.alpha

	drag_target.__is_dmc_drag = true
	display.getCurrentStage():setFocus( drag_target )


	-- start our drag operation
	self:_doDragStart( drag_target )
	self:_startListening( drag_target )

end

function DragDrop:_doDragStart( drag_target )

	local drag_target = DragDrop._drag_targets[ drag_target ]
	local dragList = self._onDragStart
	for i=1, #dragList do

		local o = dragList[ i ]
		local ds = self._registered[ o ]
		local f = ds.dragStart
		local e = {}
		e.format = drag_target.format
		e.source = o
		if ds.call_with_object then
			f( o, e )
		else
			f( e )
		end
	end
end

function DragDrop:_doDragStop()

	local dragList = self._onDragStop
	for i=1, #dragList do

		local o = dragList[ i ]
		local ds = self._registered[ o ]
		local f = ds.dragStop
		local e = {}
		e.source = o
		if ds.call_with_object then
			f( o, e )
		else
			f( e )
		end
	end
end

function DragDrop:acceptDragDrop()
	self.drop_target_accept = true
end

function DragDrop:touch( e )

	local target = e.target
	local phase = e.phase
	local result = false

	local drag_info = DragDrop._drag_targets[ target ]

	if target.__is_dmc_drag then

		if ( phase == "moved" ) then

			-- keep the dragged item moving with the touch coordinates
			target.x = e.x + drag_info.x_offset
			target.y = e.y + drag_info.y_offset

			-- see if we are over any drop targets
			local newDropTarget = self:_searchDropTargets( e.x, e.y )

			if DragDrop.drop_target == newDropTarget then
				-- same object, so call dragOver()
				if DragDrop.drop_target and DragDrop.drop_target_accept then

					local o = newDropTarget
					local ds = self._registered[ o ]
					local f = ds.dragOver
					if f then
						local e = {}
						e.format = drag_info.format
						e.source = o
						if ds.call_with_object then
							result = f( o, e )
						else
							result = f( e )
						end
					end
				end

			elseif DragDrop.drop_target ~= newDropTarget then
				-- new target is nil,
				-- we exited, so call dragExit()
				if DragDrop.drop_target and DragDrop.drop_target_accept then

					local o = DragDrop.drop_target
					local ds = self._registered[ o ]
					local f = ds.dragExit
					if f then
						local e = {}
						e.format = drag_info.format
						e.source = o
						if ds.call_with_object then
							result = f( o, e )
						else
							result = f( e )
						end
					end
				end

				self.drop_target_accept = false

				-- call dragEnter on newDropTarget
				if newDropTarget then
					local o = newDropTarget
					local ds = self._registered[ newDropTarget ]
					local f = ds.dragEnter
					if f then
						local e = {}
						e.format = drag_info.format
						e.source = o
						if ds.call_with_object then
							result = f( ds.obj, e )
						else
							result = f( e )
						end
					end
				end
			end

			DragDrop.drop_target = newDropTarget

		elseif phase == "ended" or phase == "cancelled" then
			local func

			if phase == "ended" then

				if DragDrop.drop_target and DragDrop.drop_target_accept then
					-- same object, so call dragDrop()

					local o = DragDrop.drop_target
					local ds = self._registered[ o ]
					local f = ds.dragDrop
					if f then
						local e = {}
						e.format = drag_info.format
						e.source = o
						if ds.call_with_object then
							result = f( o, e )
						else
							result = f( e )
						end
					end
					-- keep on Drop Target, and shrink
					func = self:_createEndAnimation( { x=o.x, y=o.y,
						time=DragDrop.ANIMATE_TIME_FAST,
						resize=true, drag_target=target
					})
				else
					-- drop not accepted, so move back to drag origin
					func = self:_createEndAnimation({ x=drag_info.origin.x,
						y=drag_info.origin.y, time=DragDrop.ANIMATE_TIME_SLOW,
						resize=false, drag_target=target
					})
				end

			end

			self.drop_target = nil
			self.drop_target_accept = false

			self:_doDragStop()
			self:_stopListening( target )
			func()

			target.__is_dmc_drag = nil
			display.getCurrentStage():setFocus( nil )

		end
	end

	return result
end

function DragDrop:_createEndAnimation( params )

	local params = params or {}
	local default_transition_time = 600
	local fDelete, doFunc

	local drag_target = params.drag_target

	-- create final removal
	fDelete = function( e )
		local dt = drag_target
		DragDrop._drag_targets[ dt ] = nil
		dt:removeSelf()
	end

	-- move and/or shrink the object

	local p = {}
	p.onComplete = fDelete
	p.time = params.time or default_transition_time
	p.x = params.x
	p.y = params.y
	if params.resize then
		p.width = 10 ; p.height = 10
	end

	doFunc = function( e )
		transition.to( drag_target, p )
	end

	return doFunc
end


function DragDrop:_startListening( drag_target )
	local drag_info = DragDrop._drag_targets[ drag_target ]
	drag_info.source:addEventListener( "touch", self )
end

function DragDrop:_stopListening( drag_target )
	local drag_info = DragDrop._drag_targets[ drag_target ]
	drag_info.source:removeEventListener( "touch", self )
end

function DragDrop:_searchDropTargets( x, y )
	local dropList = self._registered
	for k, _ in pairs( dropList ) do
		local o = k
		if not isDisplayObject( k ) then
			o = k[ DragDrop.DISPLAY_PROPERTY ]
			if o == nil then
				print( "\nWARNING: object not of type Corona Display nor does it have display property '" .. DragDrop.DISPLAY_PROPERTY .. "'\n" )
			end
		end
		local bounds = o.contentBounds

		local isWithinBounds =
			bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
		if isWithinBounds then return k end
	end

	return nil
end


return DragDrop

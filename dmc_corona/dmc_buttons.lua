
--====================================================================--
-- dmc_buttons.lua
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/dmc_buttons.lua
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
-- DMC Corona Library : DMC Buttons
--====================================================================--

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.9.0"



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
-- DMC Buttons
--====================================================================--


--====================================================================--
-- Configuration

dmc_lib_data.dmc_buttons = dmc_lib_data.dmc_buttons or {}

local DMC_BUTTONS_DEFAULTS = {
	debug_active=false,
}

local dmc_states_data = Utils.extend( dmc_lib_data.dmc_buttons, DMC_BUTTONS_DEFAULTS )


--====================================================================--
-- Imports

local Objects = require 'dmc_objects'
local Utils = require 'dmc_utils'

local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase



--====================================================================--
-- Buttons base class
--====================================================================--

local ButtonBase = inheritsFrom( CoronaBase )
ButtonBase.NAME = "Button Base"
ButtonBase._SUPPORTED_VIEWS = nil

ButtonBase._PRINT_INCLUDE = Utils.extend( CoronaBase._PRINT_INCLUDE, { '_img_info', '_img_data', '_callback' } )
ButtonBase._PRINT_EXCLUDE = Utils.extend( CoronaBase._PRINT_EXCLUDE, {} )

ButtonBase.PHASE_PRESS = "press"
ButtonBase.PHASE_RELEASE = "release"


-- create a base image configuration
-- copied into state-specific tables
ButtonBase._BASE_IMAGE_CONFIG = {
	source = "",
	width = 0,
	height = 0,
	xOffset = 0,
	yOffset = 0,
	label = nil,
}
-- create a base label style configuration
-- copied into state-specific tables
ButtonBase._BASE_STYLE_CONFIG = {
	font = native.systemFontBold,
	size = 17,
	color = { 255, 255, 255, 255 },
	xOffset = 0,
	yOffset = 0,
}



-- =============================
-- Constructor from CoronaBase
-- =============================


function ButtonBase:_init( options )
	--print( "in ButtonBase:_init()" )
	self:superCall( "_init" )

	if self._SUPPORTED_VIEWS == nil then return end

	local options = options or {}

	-- create properties
	self.id = ""
	self._img_info = {}
	self._img_data = {}
	self._callback = {
		onPress = nil,
		onRelease = nil,
		onEvent = nil,
	}

	-- setup our image info structure
	self:_setImageInfo()

end



--	_setImageInfo()
--
-- setup the default parameters for each image state
--
function ButtonBase:_setImageInfo()

	local img_list = self._SUPPORTED_VIEWS
	local img_info = self._img_info

	for i=1, #img_list do
		local t = img_list[ i ] -- image string, eg 'active'
		img_info[ t ] = Utils.extend( self._BASE_IMAGE_CONFIG, {} )
		img_info[ t ].style = Utils.extend( self._BASE_STYLE_CONFIG, {} )
	end

end


-- _createView()
--
-- create all of the display items for each image state
--
function ButtonBase:_createView()

	if self._SUPPORTED_VIEWS == nil then return end

	local img_info, img_data = self._img_info, self._img_data
	local group, grp_info, img, label

	local img_list = self._SUPPORTED_VIEWS

	for i=1, #img_list do
		local t = img_list[ i ] -- image string, eg 'active'

		-- do Corona stuff
		grp_info = img_info[ t ]
		group = display.newGroup()

		-- save to our object for reference
		img_data[ t ] = group
		self:insert( group, true )
		group:addEventListener( "touch", self )


		-- setup image
		img = display.newImageRect( grp_info.source,
					grp_info.width,
					grp_info.height )
		if img == nil then
			print("\nERROR: image rect source '" .. tostring( grp_info.source ) .. "'\n\n" )
		end
		group:insert( img )

		-- setup label
		if ( grp_info.label ) then
			label = display.newText( grp_info.label, 0, 0, grp_info.style.font, grp_info.style.size )
			label:setTextColor( unpack( grp_info.style.color ) )

			group:insert( label )
			label:setReferencePoint( display.CenterReferencePoint )
			label.x, label.y = grp_info.style.xOffset, grp_info.style.yOffset
		end

	end

end

function ButtonBase:destroy()
	--print( "in ButtonBase:destroy()" )

	local img_info, img_data = self._img_info, self._img_data
	local img_list = self._SUPPORTED_VIEWS

	for i=1, #img_list do
		local obj, group
		local t = img_list[ i ] -- image string, eg 'active'

		Utils.destroy( img_info[ t ] )
		img_info[ t ] = nil

		-- get rid of image state groups ( display objects )
		group = img_data[ t ]
		while group.numChildren > 0 do
			obj = group[1]
			group:remove( obj )
			--obj:removeSelf()
		end
		group:removeEventListener( "touch", self )
		self:remove( group )
		img_data[ t ] = nil

	end

	self._img_info = nil
	self._img_data = nil
	self._callback = nil

	-- call after we do our cleanup
	CoronaBase.destroy( self )

end



--== PUBLIC METHODS ============================================

-- x()
--
-- overridden from super
--
function ButtonBase.__setters:x( value )

	local img_list = self._SUPPORTED_VIEWS
	local i

	for i=1, #img_list do
		local t = img_list[ i ] -- 'active'
		local img = self._img_data[ t ]
		img.x = value + self._img_info[ t ].xOffset
	end

end

-- y()
--
-- overridden from super
--
function ButtonBase.__setters:y( value )

	local img_list = self._SUPPORTED_VIEWS
	local i

	for i=1, #img_list do
		local t = img_list[ i ] -- 'active'
		local img = self._img_data[ t ]
		img.y = value + self._img_info[ t ].yOffset
	end

end



--====================================================================--
-- Push Button class
--====================================================================--

local PushButton = inheritsFrom( ButtonBase )
PushButton.NAME = "Push Button"
PushButton._SUPPORTED_VIEWS = { "up", "down" }


function PushButton:_init( options )
	--print( "in PushButton:_init()'")
	self:superCall( "_init" )

	local options = options or {}
	local img_info, img_data = self._img_info, self._img_data


	-- == define our properties ====================

	-- these are display objects
	img_data.default = nil
	img_data.down = nil

	-- setup our image info structure
	self:_setImageInfo()


	-- == overlay incoming options ====================

	-- do top-level options first
	if options.id then
		self.id = options.id
	end

	if options.height then
		img_info.up.height = options.height
		img_info.down.height = options.height
	end
	if options.width then
		img_info.up.width = options.width
		img_info.down.width = options.width
	end
	if options.label then
		img_info.up.label = options.label
		img_info.down.label = options.label
	end
	if options.defaultSrc then
		img_info.up.source = options.defaultSrc
		img_info.down.source = options.defaultSrc
	end
	if options.upSrc then
		img_info.up.source = options.upSrc
	end
	if options.downSrc then
		img_info.down.source = options.downSrc
	end

	if options.style then
		Utils.extend( options.style, img_info.up.style )
		Utils.extend( options.style, img_info.down.style )
	end

	-- now do second-level options

	if options.up then
		Utils.extend( options.up, img_info.up )
		end
	if options.down then
		Utils.extend( options.down, img_info.down )
	end

	if options.onPress and type( options.onPress ) == "function" then
		self._callback.onPress = options.onPress
	end
	if options.onRelease and type( options.onRelease ) == "function" then
		self._callback.onRelease = options.onRelease
	end
	if options.onEvent and type( options.onEvent ) == "function" then
		self._callback.onEvent = options.onEvent
	end

end


function PushButton:_initComplete()

	local img_data = self._img_data
	img_data.up.isVisible = true
	img_data.down.isVisible = false

end


function PushButton:touch( e )

	local phase = e.phase

	local img_data = self._img_data
	local onEvent = self._callback.onEvent
	local onPress = self._callback.onPress
	local onRelease = self._callback.onRelease
	local result = true

	local buttonEvent = {}
	buttonEvent.target = self
	buttonEvent.id = self.id

	-- phase "BEGAN"
	if phase == "began" then

		buttonEvent.phase = ButtonBase.PHASE_PRESS
		buttonEvent.name = "touch"

		if onPress then
			result = onPress( e )
		elseif ( onEvent ) then
			result = onEvent( buttonEvent )
		end

		self:dispatchEvent( buttonEvent )

		display.getCurrentStage():setFocus( e.target )
		self.isFocus = true
		img_data.down.isVisible = true
		img_data.up.isVisible = false

	elseif self.isFocus then

		-- check if touch is over the button
		local bounds = self.contentBounds
		local x,y = e.x,e.y
		local isWithinBounds =
			bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y

		-- phase "MOVED"
		if phase == "moved" then

			-- show correct image state
			img_data.down.isVisible = isWithinBounds
			img_data.up.isVisible = not isWithinBounds

		-- phase "ENDED"
		elseif phase == "ended" or phase == "cancelled" then

			if phase == "ended" then

				buttonEvent.phase = ButtonBase.PHASE_RELEASE
				buttonEvent.name = "touch"

				if isWithinBounds then
					if onRelease then
						result = onRelease( e )
					elseif onEvent then
						result = onEvent( buttonEvent )
					end

					self:dispatchEvent( buttonEvent )
				end
			end

			display.getCurrentStage():setFocus( nil )
			self.isFocus = false
			img_data.down.isVisible = false
			img_data.up.isVisible = true

		end
	end

	return result
end



--====================================================================--
-- BinaryButton button class
--====================================================================--

local BinaryButton = inheritsFrom( ButtonBase )
BinaryButton.NAME = "Binary Button"
BinaryButton._SUPPORTED_VIEWS = { 'active', 'inactive' }

BinaryButton.STATE_INACTIVE = "inactive"
BinaryButton.STATE_ACTIVE = "active"



function BinaryButton:new( options )

	local o = self:_bless()
	o:_init( options )
	if options then o:_createView() end

	return o
end


function BinaryButton:_init( options )

	self:superCall( "_init" )

	local options = options or {}
	local img_info, img_data = self._img_info, self._img_data


	-- == define our properties ====================

	self.state = ""
	-- these are display objects
	img_data.active = nil
	img_data.inactive = nil

	-- setup our image info structure
	self:_setImageInfo()


	-- == overlay incoming options ====================

	-- do top-level options first
	if options.id then
		self.id = options.id
	end

	if options.height then
		img_info.active.height = options.height
		img_info.inactive.height = options.height
	end
	if options.width then
		img_info.active.width = options.width
		img_info.inactive.width = options.width
	end
	if options.label then
		img_info.active.label = options.label
		img_info.inactive.label = options.label
	end
	if options.defaultSrc then
		img_info.active.source = options.defaultSrc
		img_info.inactive.source = options.defaultSrc
	end
	if options.inactiveSrc then
		img_info.inactive.source = options.inactiveSrc
	end
	if options.activeSrc then
		img_info.active.source = options.activeSrc
	end

	if options.style then
		Utils.extend( options.style, img_info.active.style )
		Utils.extend( options.style, img_info.inactive.style )
	end

	-- now do second-level options

	if options.active then
		Utils.extend( options.active, img_info.active )
		end
	if options.inactive then
		Utils.extend( options.inactive, img_info.inactive )
	end

	if options.onPress and type( options.onPress ) == "function" then
		self._callback.onPress = options.onPress
	end
	if options.onRelease and type( options.onRelease ) == "function" then
		self._callback.onRelease = options.onRelease
	end
	if options.onEvent and type( options.onEvent ) == "function" then
		self._callback.onEvent = options.onEvent
	end

end

function BinaryButton:_initComplete()

	local img_data = self._img_data
	img_data.active.isVisible = false
	img_data.inactive.isVisible = true
	self:_setButtonState( BinaryButton.STATE_INACTIVE )

end


function BinaryButton:getNextState()
	-- override this
end

function BinaryButton:touch( e )

	local phase = e.phase

	local onEvent = self._callback.onEvent
	local onPress = self._callback.onPress
	local onRelease = self._callback.onRelease
	local result = true

	local buttonEvent = {}
	buttonEvent.target = self
	buttonEvent.id = self.id
	buttonEvent.state = self.state

	local current_state = self.state
	local other_state = self:getNextState()

	-- phase "BEGAN"
	if phase == "began" then

		buttonEvent.phase = ButtonBase.PHASE_PRESS
		buttonEvent.name = "touch"

		if onPress then
			result = onPress( e )
		elseif onEvent then
			result = onEvent( buttonEvent )
		end

		self:dispatchEvent( buttonEvent )
		self:_setButtonImage( other_state )

		display.getCurrentStage():setFocus( e.target )
		self.isFocus = true

	elseif self.isFocus then

		-- check if touch is over the button
		local bounds = self.contentBounds
		local x,y = e.x,e.y
		local isWithinBounds =
			bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y

		-- phase "MOVED"
		if phase == "moved" then

			--print ("moved")
			if isWithinBounds then
				self:_setButtonImage( other_state )
			else
				self:_setButtonImage( current_state )
			end


		-- phase "ENDED"
		elseif phase == "ended" or phase == "cancelled" then

			if phase == "ended" then

				buttonEvent.phase = ButtonBase.PHASE_RELEASE
				buttonEvent.name = "touch"

				if isWithinBounds then
					local state = BinaryButton.STATE_INACTIVE
					if self.state == state then
						state = BinaryButton.STATE_ACTIVE
					end

					self:_setButtonState( state )
					buttonEvent.state = self.state

					if onRelease then
						result = onRelease( e )
					elseif onEvent then
						result = onEvent( buttonEvent )
					end

					self:dispatchEvent( buttonEvent )
				end
			end

			display.getCurrentStage():setFocus( nil )
			self.isFocus = false
			self:_setButtonImage()

		end
	end

	return result
end

function BinaryButton:_setButtonState( value )

	-- no need to update if the same state
	if self.state == value then return end

	-- save the new state
	self.state = value

	self:_setButtonImage( value )

end

function BinaryButton:_setButtonImage( value )

	local value = value or self.state
	local img_data = self._img_data

	-- change button view to reflect the current state
	local showInactive = value == BinaryButton.STATE_INACTIVE

	img_data.inactive.isVisible = showInactive
	img_data.active.isVisible = not showInactive

end




--====================================================================--
-- Toggle Button class
--====================================================================--

local ToggleButton = inheritsFrom( BinaryButton )
ToggleButton.NAME = "Toggle Button"


-- for use with "down" image state
function ToggleButton:getNextState()
	local state = BinaryButton.STATE_INACTIVE
	if self.state == state then
		state = BinaryButton.STATE_ACTIVE
	end
	return state
end




--====================================================================--
-- Radio Button class
--====================================================================--

local RadioButton = inheritsFrom( BinaryButton )
RadioButton.NAME = "Radio Button"

-- for use with "down" image state
function RadioButton:getNextState()
	return BinaryButton.STATE_ACTIVE
end




--====================================================================--
-- Button Group base class
--====================================================================--

local ButtonGroupBase = inheritsFrom( CoronaBase )
ButtonGroupBase.NAME = "Button Group Base"

ButtonGroupBase._PRINT_INCLUDE = Utils.extend( CoronaBase._PRINT_INCLUDE, { '_group_buttons', '_selected_button' } )
ButtonGroupBase._PRINT_EXCLUDE = Utils.extend( CoronaBase._PRINT_EXCLUDE, {} )


function ButtonGroupBase:new( options )

	local o = self:_bless()
	o:_init( options )

	return o
end


function ButtonGroupBase:_init( options )

	self:superCall( "_init" )

	-- create properties
	self.setFirstActive = nil		-- whether first load button is set to state active
	self._group_buttons = {}		-- table of our buttons to control
	self._selected_button = nil	-- this is handle to real object, not display

	-- overlay incoming options
	if options then Utils.extend( options, self ) end

end


function ButtonGroupBase:add( obj, params )

	local params = params or {}
	-- these are options which can be passed in
	local opts = {
		setActive = false,
	}

	-- process incoming options
	Utils.extend( params, opts )

	-- if this is the first button, make it active
	if ( self.setFirstActive and #self._group_buttons == 0 ) or opts.setActive then
		self:_setButtonGroupState( ToggleButton.STATE_INACTIVE, opts )
		obj:_setButtonState( ToggleButton.STATE_ACTIVE )
		self._selected_button = obj
	end

	-- do corona stuff
	self:insert( obj.display )

	obj:addEventListener( "touch", self )

	-- add to our button array
	table.insert( self._group_buttons, obj )

end

function ButtonGroupBase:destroy()
	--print ( "in ButtonGroupBase:destroy()")

	self._selected_button = nil

	-- remove our buttons
	while #self._group_buttons > 0 do
		local button = table.remove( self._group_buttons, 1 )
		button:removeEventListener( "touch", self )
		button:destroy()
	end

	self._group_buttons = nil

	-- call after we do our cleanup
	CoronaBase.destroy( self )
end

function ButtonGroupBase:_setButtonGroupState( value )

	for i=1, table.getn( self._group_buttons ) do
		self._group_buttons[ i ]:_setButtonState( value )
	end

end




--====================================================================--
-- Radio Group class
--====================================================================--

local RadioGroup = inheritsFrom( ButtonGroupBase )
RadioGroup.NAME = "Radio Group"


function RadioGroup:_init( options )

	-- initialize with properties from super class
	self:superCall( "_init" )

	-- add new properties specific to our class
	self.setFirstActive = true		-- for first loaded button

	-- set our properties with incoming options
	if options then Utils.extend( options, self ) end

end


function RadioGroup:touch( e )

	local btn = e.target
	local button_label = e.id

	if e.phase == ButtonBase.PHASE_RELEASE then

		local sendEvent = true
		if self._selected_button == btn then sendEvent = false end

		-- turn all buttons off
		self:_setButtonGroupState( ToggleButton.STATE_INACTIVE )

		-- save selected button and set it to ON
		self._selected_button = btn
		btn:_setButtonState( ToggleButton.STATE_ACTIVE )

		if sendEvent then
			self:dispatchEvent( { name="change", target=btn, label=button_label, state=btn.state } )
		end

		return true
	end

end



--====================================================================--
-- Toggle Group class
--====================================================================--

local ToggleGroup = inheritsFrom( ButtonGroupBase )
ToggleGroup.NAME = "Toggle Group"


function ToggleGroup:_init( options )

	-- initialize with properties from above
	self:superCall( "_init" )

	-- add new properties specific to our class
	self.setFirstActive = false		-- for first loaded button

	-- set our properties with incoming options
	if options then Utils.extend( options, self ) end

end


function ToggleGroup:touch( e )

	local btn = e.target
	local btn_label = e.id

	if e.phase == ButtonBase.PHASE_RELEASE then

		-- if we have different button and the new state is STATE_ACTIVE
		if self._selected_button ~= btn and e.state == ToggleButton.STATE_ACTIVE then
			-- turn all buttons off
			self:_setButtonGroupState( ToggleButton.STATE_INACTIVE )

			-- save button and set it to ON
			self._selected_button = btn
			btn:_setButtonState( ToggleButton.STATE_ACTIVE )
		end

		self:dispatchEvent( { name="change", target=btn, label=btn_label, state=btn.state } )

		return true
	end

end




-- =========================================================
-- Button Factory
-- =========================================================


local Buttons = {}

-- export class instantiations for direct access
Buttons.ButtonBase = ButtonBase
Buttons.PushButton = PushButton
Buttons.BinaryButton = BinaryButton
Buttons.ToggleButton = ToggleButton
Buttons.RadioButton = RadioButton
Buttons.ButtonGroupBase = ButtonGroupBase
Buttons.RadioGroup = RadioGroup
Buttons.ToggleGroup = ToggleGroup

-- Button factory method

function Buttons.create( class_type, options )

	local o

	if class_type == "push" then
		o = PushButton:new( options )

	elseif class_type == "radio" then
		o = RadioButton:new( options )

	elseif class_type == "toggle" then
		o = ToggleButton:new( options )

	elseif class_type == "radioGroup" then
		o = RadioGroup:new( options )

	elseif class_type == "toggleGroup" then
		o = ToggleGroup:new( options )

	else
		print ( "ERROR: Button Class Factory - unknown class type: " .. class_type )
	end

	return o

end


return Buttons

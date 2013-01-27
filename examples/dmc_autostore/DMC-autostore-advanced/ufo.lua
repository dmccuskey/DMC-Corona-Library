
--====================================================================--
-- Imports and Setup
--====================================================================--




--====================================================================--
-- UFO base class
--====================================================================--

local UFO = {}

-- setup OO for Class
local mt = {
	__index = UFO
}
setmetatable( UFO, mt )


--==  Class constants  ==--

UFO.COOL_IMG = "assets/ufo_cool.png"
UFO.WARM_IMG = "assets/ufo_warm.png"
UFO.HOT_IMG = "assets/ufo_hot.png"
UFO.IMG_W = 110
UFO.IMG_H = 65


--==  Class constructor  ==--

function UFO:new( data )
	--print( "UFO:new" )

	local o = {}
	local mt = {
		__index = UFO
	}
	setmetatable( o, mt )

	o._data = data -- this is the autostore 'magic' branch for this object

	o:_init()

	return o
end


--==  Class Methods  ==--

-- _init()
--
-- one of the base methods to override for dmc_objects
-- put on our object properties
--
function UFO:_init()
	--print( "UFO:_init" )

	-- Create Properties --

	self._ufo_views = {}
	self._dg = display.newGroup()  -- container for our images
	self._has_moved = false  -- flag for movement / color change


	-- Create View --

	local uvs = self._ufo_views -- reference
	local img

	-- setup cool
	img = display.newImageRect( UFO.COOL_IMG, UFO.IMG_W, UFO.IMG_H )
	self._dg:insert( img )
	uvs.cool = img
	img.isVisible = false

	-- setup warm
	img = display.newImageRect( UFO.WARM_IMG, UFO.IMG_W, UFO.IMG_H )
	self._dg:insert( img )
	uvs.warm = img
	img.isVisible = false

	-- setup hot
	img = display.newImageRect( UFO.HOT_IMG, UFO.IMG_W, UFO.IMG_H )
	self._dg:insert( img )
	uvs.hot = img
	img.isVisible = false


	-- Setup Actions --

	self._dg:addEventListener( "touch", self )


	-- init Complete --

	local d = self._data
	self._dg.x = d.x
	self._dg.y = d.y

	self:_selectTempView()

end



function UFO:_selectNextTemp()

	-- autostore branch
	local d = self._data

	if d.temperature == 'cool' then
		d.temperature = 'warm'
	elseif d.temperature == 'warm' then
		d.temperature = 'hot' 
	else
		d.temperature = 'cool'
	end

	self:_selectTempView()
end



function UFO:_selectTempView()

	local t = self._data.temperature

	-- turn them all off
	self._ufo_views.cool.isVisible = false
	self._ufo_views.warm.isVisible = false
	self._ufo_views.hot.isVisible = false

		-- then select the next view to show
	if t == 'cool' then
		self._ufo_views.cool.isVisible = true
	elseif t == 'warm' then
		self._ufo_views.warm.isVisible = true
	else
		self._ufo_views.hot.isVisible = true
	end

end

-- touch()
--
-- touch handler
--
function UFO:touch( event )
	--print( "UFO:touch" )

	if event.phase == 'began' then


	elseif event.phase == 'moved' then

		self._has_moved = true

		local d = self._data
		d.x = event.x
		d.y = event.y
		self._dg.x = d.x
		self._dg.y = d.y


	else

		if self._has_moved == false then
			self:_selectNextTemp()
		end

		self._has_moved = false

	end


end




--====================================================================--
-- The UFO Factory
--====================================================================--

local UFOFactory = {}

function UFOFactory.create( data )
	return UFO:new( data )
end

return UFOFactory


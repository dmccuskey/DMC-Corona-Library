
--====================================================================--
-- Imports and Setup
--====================================================================--

-- import DMC Objects file
local Objects = require( "dmc_objects" )

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase


--====================================================================--
-- UFO class
--====================================================================--

local UFO = inheritsFrom( CoronaBase )
UFO.NAME = "Unidentified Flying Object"


-- Class constants


--==  Methods  ==--


-- _init()
--
-- one of the base methods to override for dmc_objects
-- put on our object properties
--
function UFO:_init()

	-- be sure to call this first !
	self:superCall( "_init" )

	-- == Create Properties ==

	self._circle = nil

end


-- _createView()
--
-- one of the base methods to override for dmc_objects
-- assemble the images for our object
--
function UFO:_createView()

	local o

	o = display.newCircle( 150, 375, 30 )
	o:setFillColor( 1, .5, .5 )

	self:insert( o )
	self._circle = o

end



-- The Factory

local UFOFactory = {}

function UFOFactory.create()
	return UFO:new()
end


return UFOFactory


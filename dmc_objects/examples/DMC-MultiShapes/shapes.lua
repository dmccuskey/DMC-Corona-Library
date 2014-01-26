
--====================================================================--
-- Imports and Setup
--====================================================================--

-- import DMC Objects file
local Objects = require( "dmc_objects" )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase



--====================================================================--
-- Shapes class - lines
--====================================================================--

local Shape = inheritsFrom( CoronaBase )
Shape.NAME = "Shape Base"
Shape.TRANSPARENT = { 0, 0, 0, 0 }
Shape.STROKE_WIDTH = 5

Shape.P_LIST1 = nil
Shape.P_LIST2 = nil


--== Start: Setup DMC Objects


function Shape:_init()
	self:superCall( "_init" )
	--==--

	--== Create Properties ==--

	local rand = math.random
	self.color = { rand(255), rand(255), rand(255) }

end

-- reverse init() setup
function Shape:_undoInit()
	self.color = nil

	--==--
	self:superCall( "_undoInit" )
end

-- this method works for point-base shapes
-- we will override for general functions
function Shape:_createView()
	self:superCall( "_createView" )
	--==--

	local p_list1 = self.P_LIST1
	local p_list2 = self.P_LIST2

	local o -- object tmp

	-- create a display element
	o = display.newLine( unpack( p_list1 ) )
	o:append( unpack( p_list2 ) )
	o:setColor( unpack( self.color ) )
	o.width = self.STROKE_WIDTH

	-- save in our object view, which is a display group
	self:insert( o )

end

--[[
if our setup was more complex than just Corona elements, 
we could specifically tear down the object's view here.
however, dmc_objects will automatically remove pure-Corona elements automatically
function Shape:_undoCreateView()
	--==--
	self:superCall( "_undoCreateView" )
end
--]]


--== END: Setup DMC Objects


--== Public Methods
-- none

--== Private Methods
-- none

--== Event Handlers
-- none



--====================================================================--
-- Square class
--====================================================================--

local Square = inheritsFrom( Shape )
Square.NAME = "Square"

Square.P_LIST1 = { 0, 0, 40, 40 }

-- we could make this from points, but just showing an override
function Square:_createView()

	local o -- object tmp

	-- create a display element
	o = display.newRect( unpack( self.P_LIST1 ) )
	o:setStrokeColor( unpack( self.color ) )
	o:setFillColor( unpack( Shape.TRANSPARENT ) )
	o.strokeWidth = self.STROKE_WIDTH

	-- save in our object view, display group
	self:insert( o )
end



--====================================================================--
-- Circle class
--====================================================================--

local Circle = inheritsFrom( Shape )
Circle.NAME = "Circle"

Circle.P_LIST1 = { 0, 0, 20 }


-- using Corona native circle method
function Circle:_createView()

	local o -- object tmp

	-- create a display element
	o = display.newCircle( unpack( self.P_LIST1 ) )
	o:setFillColor( unpack( Shape.TRANSPARENT ) )
	o:setStrokeColor( unpack( self.color ) )
	o.strokeWidth = self.STROKE_WIDTH

	-- save in our object view, display group
	self:insert( o )
end



--====================================================================--
-- Diamond class
--====================================================================--

local Diamond = inheritsFrom( Shape )
Diamond.NAME = "Diamond"

Diamond.P_LIST1 = { 0, -40, 20, 0 }
Diamond.P_LIST2 = { 0, 40, -20, 0, 0, -40 }



--====================================================================--
-- Hexagon class
--====================================================================--

local Hexagon = inheritsFrom( Shape )
Hexagon.NAME = "Hexagon"

Hexagon.P_LIST1 = { 0, 17.2, 10, 0 }
Hexagon.P_LIST2 = { 30, 0, 40, 17.2, 30, 34.4, 10, 34.4, 0, 17.2 }



--====================================================================--
-- Triangle class
--====================================================================--

local Triangle = inheritsFrom( Shape )
Triangle.NAME = "Triangle"

Triangle.P_LIST1 = { -30, 0, 0, 50 }
Triangle.P_LIST2 = { 30, 0, -30, 0 }




--====================================================================--
-- Shape Factory
--====================================================================--


-- Support Items

local SHAPES_LIST = { "square", "diamond", "hexagon", "triangle", "circle" }

local function selectRandomShape()
	local randRange = 100
	local randNum = math.random( randRange )

	local numShapes = table.getn( SHAPES_LIST )
	local shapeDivisor = randRange / numShapes
	local shapeIdx = math.floor( randNum / shapeDivisor )
	if randNum ~= 100 then shapeIdx = shapeIdx + 1 end

	return SHAPES_LIST[ shapeIdx ]
end


-- The Factory

local ShapeFactory = {}

function ShapeFactory.create( shape, options )

	local shapeType = shape or selectRandomShape()
	local s

	if ( shapeType == "square" ) then
		s = Square:new( options )

	elseif ( shapeType == "diamond" ) then
		s = Diamond:new( options )

	elseif ( shapeType == "circle" ) then
		s = Circle:new( options )

	elseif ( shapeType == "hexagon" ) then
		s = Hexagon:new( options )

	elseif ( shapeType == "triangle" ) then
		s = Triangle:new( options )

	else
		print ("Shape Factory, unknown shape!! " .. tostring( shapeType ) )
	end

	return s
end


return ShapeFactory


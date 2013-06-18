
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
-- Shapes class
--====================================================================--

local Shape = inheritsFrom( CoronaBase )
Shape.NAME = "Shape Base"

--== Class Constants

Shape.IMAGE = ""
Shape.IMAGE_W = 0
Shape.IMAGE_H = 0



--== Start: Setup DMC Objects


function Shape:_init()
	self:superCall( "_init" )
	--==--

	--== Create Properties ==--

	self.rotation = 0

end
-- reverse init() setup
function Shape:_undoInit()

	--==--
	self:superCall( "_undoInit" )
end

function Shape:_createView()

	local o -- object tmp

	o = display.newImageRect( self.IMAGE, self.IMAGE_W, self.IMAGE_H )
	self:insert( o )

end

--[[
if our setup was more complex than just Corona elements, 
we could specifically tear down the object's view here.
dmc_objects will remove pure-Corona elements automatically
function Shape:_undoCreateView()
	--==--
	self:superCall( "_undoCreateView" )
end
--]]


--====================================================================--
-- Square class
--====================================================================--

local Square = inheritsFrom( Shape )
Square.NAME = "Square"
Square.IMAGE = "assets/shape_square.png"
Square.IMAGE_W = 86
Square.IMAGE_H = 86


--====================================================================--
-- Diamond class
--====================================================================--

local Diamond = inheritsFrom( Shape )
Diamond.NAME = "Diamond"
Diamond.IMAGE = "assets/shape_diamond.png"
Diamond.IMAGE_W = 77
Diamond.IMAGE_H = 117


--====================================================================--
-- Hexagon class
--====================================================================--

local Hexagon = inheritsFrom( Shape )
Hexagon.NAME = "Hexagon"
Hexagon.IMAGE = "assets/shape_hexagon.png"
Hexagon.IMAGE_W = 86
Hexagon.IMAGE_H = 86


--====================================================================--
-- Circle class
--====================================================================--

local Circle = inheritsFrom( Shape )
Circle.NAME = "Circle"
Circle.IMAGE = "assets/shape_circle.png"
Circle.IMAGE_W = 86
Circle.IMAGE_H = 86


--====================================================================--
-- Triangle class
--====================================================================--

local Triangle = inheritsFrom( Shape )
Triangle.NAME = "Triangle"
Triangle.IMAGE = "assets/shape_triangle.png"
Triangle.IMAGE_W = 96
Triangle.IMAGE_H = 87





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
	local options = options or {}
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


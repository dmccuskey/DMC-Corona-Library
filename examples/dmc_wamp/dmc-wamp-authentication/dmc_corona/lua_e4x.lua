--====================================================================--
-- lua_e4x.lua
--
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_e4x.lua
--====================================================================--

--[[

The MIT License (MIT)

Copyright (C) 2014 David McCuskey. All Rights Reserved.

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
-- DMC Lua Library : Lua E4X
--====================================================================--

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.1"



--====================================================================--
-- XML Classes
--====================================================================--


--====================================================================--
-- Setup, Constants

-- forward declare
local XmlListBase, XmlList
local XmlBase, XmlDocNode, XmlDecNode, XmlNode, XmlTextNode, XmlAttrNode

local tconcat = table.concat
local tinsert = table.insert
local tremove = table.remove


--====================================================================--
-- Support Functions

local function createXmlList()
	return XmlList()
end


-- http://lua-users.org/wiki/FunctionalLibrary

-- filter(function, table)
-- e.g: filter(is_even, {1,2,3,4}) -> {2,4}
function filter(func, tbl)
	local xlist= XmlList()
	for i,v in ipairs(tbl) do
		if func(v) then
			xlist:addNode(v)
		end
	end
	return xlist
end

-- map(function, table)
-- e.g: map(double, {1,2,3})    -> {2,4,6}
function map(func, tbl)
	local xlist= XmlList()
		for i,v in ipairs(tbl) do
			xlist:addNode( func(v) )
		end
		return xlist
end

-- foldr(function, default_value, table)
-- e.g: foldr(operator.mul, 1, {1,2,3,4,5}) -> 120
function foldr(func, val, tbl)
	for i,v in pairs(tbl) do
		val = func(val, v)
	end
	return val
end


local function decodeXmlString(value)
	value = string.gsub(value, "&#x([%x]+)%;",
		function(h)
			return string.char(tonumber(h, 16))
		end)
	value = string.gsub(value, "&#([0-9]+)%;",
		function(h)
				return string.char(tonumber(h, 10))
		end)
	value = string.gsub(value, "&quot;", "\"")
	value = string.gsub(value, "&apos;", "'")
	value = string.gsub(value, "&gt;", ">")
	value = string.gsub(value, "&lt;", "<")
	value = string.gsub(value, "&amp;", "&")
	return value
end


function encodeXmlString(value)
	value = string.gsub(value, "&", "&amp;"); -- '&' -> "&amp;"
	value = string.gsub(value, "<", "&lt;"); -- '<' -> "&lt;"
	value = string.gsub(value, ">", "&gt;"); -- '>' -> "&gt;"
	value = string.gsub(value, "\"", "&quot;"); -- '"' -> "&quot;"
	value = string.gsub(value, "([^%w%&%;%p%\t% ])",
		function(c)
			return string.format("&#x%X;", string.byte(c))
		end);
	return value;
end


--====================================================================--
-- XML Class Support

local function listIndexFunc( t, k )
	-- print( "listIndexFunc", t, k )

	local o, val, f

	-- check if search for attribute with '@'
	if string.sub(k,1,1) == '@' then
		local _,_, name = string.find(k,'^@(.*)$')
		val = t:attribute(name)
	end
	if val ~= nil then return val end

	-- -- check for key directly on object
	-- val = rawget( t, k )
	-- if val ~= nil then return val end

	-- check OO hierarchy
	o = rawget( t, '__super' )
	if o then val = o[k] end
	if val ~= nil then return val end

	-- check for key in nodes
	local nodes = rawget( t, '__nodes' )
	if nodes and type(k)=='number' then
		val = nodes[k]
	elseif type(k)=='string' then
		val = t:child(k)
	end
	if val ~= nil then return val end

	return nil
end


local function indexFunc( t, k )
	-- print( "indexFunc", t, k )

	local o, val

	-- check if search for attribute with '@'
	if string.sub(k,1,1) == '@' then
		local _,_, name = string.find(k,'^@(.*)$')
		val = t:attribute(name)
	end
	if val ~= nil then return val end

	-- check for key directly on object
	-- val = rawget( t, k )
	-- if val ~= nil then return val end

	-- check OO hierarchy
	-- method lookup
	o = rawget( t, '__super' )
	if o then val = o[k] end
	if val ~= nil then return val end

	-- check for key in children
	-- dot traversal
	local children = rawget( t, '__children' )
	if children then
		val = nil
		local func = function( node )
			return ( node:name() == k )
		end
		local v = filter( func, children )
		if v:length() > 0 then
			val = v
		end
	end
	if val ~= nil then return val end

	return nil
end


local function toStringFunc( t )
	return t:toString()
end


local function bless( base, params )
	params = params or {}
	--==--
	local o = obj or {}
	local mt = {
		-- __index = indexFunc,
		__index = params.indexFunc,
		__newindex = params.newIndexFunc,
		__tostring = params.toStringFunc,
		__len = function() error( "hrererer") end
	}
	setmetatable( o, mt )

	if base and base.new and type(base.new)=='function' then
		mt.__call = base.new
	end

	o.__super = base

	return o
end


local function inheritsFrom( base_class, params, constructor )
	params = params or {}
	params.indexFunc = params.indexFunc or indexFunc

	local o

	-- TODO: work out toString method
	-- if base_class and base_class.toString and type(base_class.toString)=='function' then
	-- 	params.toStringFunc = base_class.toString
	-- end


	o = bless( base_class, params )

	-- Return the class object of the instance
	function o:class()
		return o
	end

	-- Return the superclass object of the instance
	function o:superClass()
		return base_class
	end

	-- Return true if the caller is an instance of theClass
	function o:isa( the_class )

		local b_isa = false
		local cur_class = o

		while ( cur_class ~= nil ) and ( b_isa == false ) do
			if cur_class == the_class then
				b_isa = true
			else
				cur_class = cur_class:superClass()
			end
		end
		return b_isa
	end

	return o
end


--====================================================================--
-- XML List Base

XmlListBase = inheritsFrom( nil )

function XmlListBase:new( params )
	-- print("XmlListBase:new")
	local o = self:_bless()
	if o._init then o:_init( params ) end
	return o
end
function XmlListBase:_bless( obj )
	-- print("XmlListBase:_bless")
	local p = {
		indexFunc=listIndexFunc,
		newIndexFunc=listNewIndexFunc,
	}
	return bless( self, p )
end


--====================================================================--
-- XML List

XmlList = inheritsFrom( XmlListBase )
XmlList.NAME = 'XML List'

function XmlList:_init( params )
	-- print("XmlList:_init")
	self.__nodes = {}
end


function XmlList:addNode( node )
	-- print( "XmlList:addNode", node.NAME  )
	assert( node ~= nil, "XmlList:addNode, node can't be nil" )
	--==--

	local nodes = rawget( self, '__nodes' )
	if not node:isa( XmlList ) then
		tinsert( nodes, node )
	else
		-- process XML List
		for i,v in node:nodes() do
			-- print('dd>> ', i,v, v.NAME)
			tinsert( nodes, v )
		end
	end
end

function XmlList:attribute( key )
	-- print( "XmlList:attribute", key  )
	local result = XmlList()
	for _, node in self:nodes() do
		result:addNode( node:attribute( key ) )
	end
	return result
end

function XmlList:child( name )
	-- print( "XmlList:child", name  )
	local nodes, func, result
	result = XmlList()
	for _, node in self:nodes() do
		result:addNode( node:child( name ) )
	end
	return result
end

function XmlList:length()
	local nodes = rawget( self, '__nodes' )
	return #nodes
end

-- iterator, used in for X in ...
function XmlList:nodes()
	local pos = 1
	local nodes = rawget( self, '__nodes' )
	return function()
		while pos <= #nodes do
			local val = nodes[pos]
			local i = pos
			pos=pos+1
			return i, val
		end
		return nil, nil
	end
end

function XmlList:toString()
	-- error("error XmlList:toString")
	local nodes = rawget( self, '__nodes' )
	if #nodes == 0 then return nil end
	local func = function( val, node )
		return val .. node:toString()
	end
	return foldr( func, "", nodes )
end

function XmlList:toXmlString()
	error( "XmlList:toXmlString, not implemented" )
end


--====================================================================--
-- XML Base

XmlBase = inheritsFrom( nil )

function XmlBase:new( params )
	-- print("XmlBase:new")
	local o = self:_bless()
	if o._init then o:_init( params ) end
	return o
end

function XmlBase:_bless( obj )
	-- print("XmlBase:_bless")
	local p = {
		indexFunc=indexFunc,
		newIndexFunc=nil,
	}
	return bless( self, p )
end


--====================================================================--
-- XML Declaration Node

XmlDecNode = inheritsFrom( XmlBase )
XmlDecNode.NAME = 'XML Node'

function XmlDecNode:_init( params )
	-- print("XmlDecNode:_init")
	params = params or {}

	self.__attrs = {}

end

function XmlDecNode:addAttribute( node )
	self.__attrs[ node:name() ] = node
end


--====================================================================--
-- XML Node

XmlNode = inheritsFrom( XmlBase )
XmlNode.NAME = 'XML Node'

function XmlNode:_init( params )
	-- print("XmlNode:_init")
	params = params or {}

	self.__parent = params.parent
	self.__name = params.name
	self.__children = {}
	self.__attrs = {}

end


function XmlNode:parent()
	return rawget( self, '__parent' )
end

function XmlNode:addAttribute( node )
	self.__attrs[ node:name() ] = node
end

-- return XmlList
function XmlNode:attribute( name )
	-- print("XmlNode:attribute", name )
	if name == '*' then return self:attributes() end
	local attrs = rawget( self, '__attrs' )
	local result = XmlList()
	local attr = attrs[ name ]
	if attr then
		result:addNode( attr )
	end
	return result
end
function XmlNode:attributes()
	local attrs = rawget( self, '__attrs' )
	local result = XmlList()
	for k,attr in pairs(attrs) do
		result:addNode( attr )
	end
	return result
end

-- hasOwnProperty("@ISBN") << attribute
-- hasOwnProperty("author") << element
-- returns boolean
function XmlNode:hasOwnProperty( key )
	-- print("XmlNode:hasOwnProperty", key)
	if string.sub(key,1,1) == '@' then
		local _,_, name = string.find(key,'^@(.*)$')
		return ( self:attribute(name):length() > 0 )
	else
		return ( self:child(key):length() > 0 )
	end
end


function XmlNode:hasSimpleContent()
	local is_simple = true
	local children = rawget( self, '__children' )
	for k,node in pairs( children ) do
		-- print(k,node)
		if node:isa( XmlNode ) then is_simple = false end
		if not is_simple then break end
	end
	return is_simple
end
function XmlNode:hasComplexContent()
	return not self:hasSimpleContent()
end

function XmlNode:length()
	return 1
end


function XmlNode:name()
	return self.__name
end
function XmlNode:setName( value )
	self.__name = value
end


function XmlNode:addChild( node )
	table.insert( self.__children, node )
end
function XmlNode:child( name )
	-- print("XmlNode:child", self, name )
	local children = rawget( self, '__children' )
	local func = function( node )
		return ( node:name() == name )
	end
	return filter( func, children )
end
function XmlNode:children()
	local children = rawget( self, '__children' )
	local func = function( node )
		return true
	end
	return filter( func, children )
end


function XmlNode:toString()
	return self:_childrenContent()
end

function XmlNode:toXmlString()
	local str_t = {
		"<"..self.__name,
		self:_attrContent(),
		">",
		self:_childrenContent(),
		"</"..self.__name..">",
	}
	return table.concat( str_t, '' )
end

function XmlNode:_childrenContent()
	local children = rawget( self, '__children' )
	local func = function( val, node )
		return val .. node:toXmlString()
	end
	return foldr( func, "", children )
end

function XmlNode:_attrContent()
	local attrs = rawget( self, '__attrs' )
	table.sort( attrs ) -- apply some consistency
	local str_t = {}
	for k, attr in pairs( attrs ) do
		tinsert( str_t, attr:toXmlString() )
	end
	if #str_t > 0 then
		tinsert( str_t, 1, '' ) -- insert blank space
	end
	return tconcat( str_t, ' ' )
end


--====================================================================--
-- XML Doc Node

XmlDocNode = inheritsFrom( XmlNode )
XmlDocNode.NAME = "Attribute Node"

function XmlDocNode:_init( params )
	-- print("XmlDocNode:_init")
	params = params or {}
	XmlNode._init( self, params )

	self.declaration = params.declaration

end


--====================================================================--
-- XML Attribute Node

XmlAttrNode = inheritsFrom( XmlBase )
XmlAttrNode.NAME = "Attribute Node"

function XmlAttrNode:_init( params )
	-- print("XmlAttrNode:_init", params.name )
	params = params or {}

	self.__name = params.name
	self.__value = params.value

end


function XmlAttrNode:name()
	return self.__name
end
function XmlAttrNode:setName( value )
	self.__name = value
end

function XmlAttrNode:toString()
	-- print("XmlAttrNode:toString")
	return self.__value
end
function XmlAttrNode:toXmlString()
	return self.__name..'="'..self.__value..'"'
end


--====================================================================--
-- XML Text Node

XmlTextNode = inheritsFrom( XmlBase )
XmlTextNode.NAME = "Text Node"

function XmlTextNode:_init( params )
	-- print("XmlTextNode:_init")
	params = params or {}

	self.__text = params.text or ""
end

function XmlTextNode:toString()
	return self.__text
end
function XmlTextNode:toXmlString()
	return self.__text
end



--====================================================================--
-- XML Parser
--====================================================================--


-- https://github.com/PeterHickman/plxml/blob/master/plxml.lua
-- https://developer.coronalabs.com/code/simple-xml-parser
-- https://github.com/Cluain/Lua-Simple-XML-Parser/blob/master/xmlSimple.lua
-- http://lua-users.org/wiki/LuaXml

local XmlParser = {}

XmlParser.XML_DECLARATION_RE = '<?xml (.-)?>'
XmlParser.XML_TAG_RE = '<(%/?)([%w:-]+)(.-)(%/?)>'
XmlParser.XML_ATTR_RE = "([%-_%w]+)=([\"'])(.-)%2"


function XmlParser:decodeXmlString(value)
	return decodeXmlString(value)
end


function XmlParser:parseAttributes( node, attr_str )
	string.gsub(attr_str, XmlParser.XML_ATTR_RE, function( key, _, val )
		local attr = XmlAttrNode( {name=key, value=val} )
		node:addAttribute( attr )
	end)
end


-- creates top-level Document Node
function XmlParser:parseString( xml_str )
	-- print( "XmlParser:parseString" )

	local root = XmlDocNode()
	local node
	local si, ei, close, label, attrs, empty
	local text, lval
	local pos = 1

	--== declaration

	si, ei, attrs = string.find(xml_str, XmlParser.XML_DECLARATION_RE, pos)

	if not si then
		-- error("no declaration")
	else
		node = XmlDecNode()
		self:parseAttributes( node, attrs )
		root.declaration = node
		pos = ei + 1
	end

	--== doc type
	-- pos = ei + 1

	--== document root element

	si,ei,close,label,attrs,empty = string.find(xml_str, XmlParser.XML_TAG_RE, pos)
	text = string.sub(xml_str, pos, si-1)
	if not string.find(text, "^%s*$") then
		root:addChild( XmlTextNode( {text=decodeXmlString(text)} ) )
	end

	pos = ei + 1

	if close == "" and empty == "" then -- start tag
		root:setName( label )
		self:parseAttributes( root, attrs )

		pos = self:_parseString( xml_str, root, pos )

	elseif empty == '/' then -- empty element tag
		root:setName( label )

	else
		error( "malformed XML in XmlParser:parseString" )

	end

	return root
end


-- recursive method
--
function XmlParser:_parseString( xml_str, xml_node, pos )
	-- print( "XmlParser:_parseString", xml_node:name(), pos )

	local si, ei, close, label, attrs, empty
	local node

	while true do

		si,ei,close,label,attrs,empty = string.find(xml_str, XmlParser.XML_TAG_RE, pos)
		if not si then break end

		local text = string.sub(xml_str, pos, si-1)
		if not string.find(text, "^%s*$") then
			local node = XmlTextNode( {text=decodeXmlString(text),parent=xml_node} )
			xml_node:addChild( node )
		end

		pos = ei + 1

		if close == "" and empty == "" then   -- start tag of doc
			local node = XmlNode( {name=label,parent=xml_node} )
			self:parseAttributes( node, attrs )
			xml_node:addChild( node )

			pos = self:_parseString( xml_str, node, pos )

		elseif empty == "/" then  -- empty element tag
			local node = XmlNode( {name=label,parent=xml_node} )
			self:parseAttributes( node, attrs )
			xml_node:addChild( node )

		else  -- end tag
			assert( xml_node:name() == label, "incorrect closing label found:" )
			break

		end

	end

	return pos
end



--====================================================================--
-- Lua E4X API
--====================================================================--


local function parse( xml_str )
	-- print( "LuaE4X.parse" )
	assert( type(xml_str)=='string', 'Lua E4X: missing XML data to parse' )
	assert( #xml_str > 0, 'Lua E4X: XML data must have length' )
	return XmlParser:parseString( xml_str )
end

local function load( file )
	print("LuaE4X.load")
end

local function save( xml_node )
	print("LuaE4X.save")
end



--====================================================================--
-- Lua E4X Facade
--====================================================================--


return {
	Parser=XmlParser,
	XmlListClass=XmlList,
	XmlNodeClass=XmlNode,

	load=load,
	parse=parse,
	save=save
}

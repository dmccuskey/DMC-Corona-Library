--====================================================================--
-- lua_e4x.lua
--
-- Documentation: https://github.com/dmccuskey/lua-e4x
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

local VERSION = "0.2.0"



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
local function filter(func, tbl)
	local xlist= XmlList()
	for i,v in ipairs(tbl) do
		if func(v) then
			xlist:addNode(v)
		end
	end
	return xlist
end

-- foldr(function, default_value, table)
-- e.g: foldr(operator.mul, 1, {1,2,3,4,5}) -> 120
local function foldr(func, val, tbl)
	for i,v in ipairs(tbl) do
		val = func(val, v)
	end
	return val
end


-- UTF-8 bytes of a code point, nil if it isn't one
local function utf8Char( code )
	if not code or code < 0 or code > 0x10FFFF then
		return nil
	elseif code < 0x80 then
		return string.char( code )
	elseif code < 0x800 then
		return string.char( 0xC0 + math.floor( code / 0x40 ),
			0x80 + code % 0x40 )
	elseif code < 0x10000 then
		return string.char( 0xE0 + math.floor( code / 0x1000 ),
			0x80 + math.floor( code / 0x40 ) % 0x40, 0x80 + code % 0x40 )
	else
		return string.char( 0xF0 + math.floor( code / 0x40000 ),
			0x80 + math.floor( code / 0x1000 ) % 0x40,
			0x80 + math.floor( code / 0x40 ) % 0x40, 0x80 + code % 0x40 )
	end
end

local XML_ENTITIES = {
	amp='&', lt='<', gt='>', quot='"', apos="'"
}

-- one pass, so '&amp;lt;' becomes '&lt;', not '<'
-- an unknown entity is left as it is
local function decodeXmlString( value )
	return ( string.gsub( value, '&(#?[%w]+);', function( ent )
		local char
		if string.sub( ent, 1, 2 ) == '#x' then
			char = utf8Char( tonumber( string.sub( ent, 3 ), 16 ) )
		elseif string.sub( ent, 1, 1 ) == '#' then
			char = utf8Char( tonumber( string.sub( ent, 2 ), 10 ) )
		else
			char = XML_ENTITIES[ ent ]
		end
		return char -- nil keeps the entity
	end ) )
end

local function encodeXmlText( value )
	value = string.gsub( value, '&', '&amp;' )
	value = string.gsub( value, '<', '&lt;' )
	value = string.gsub( value, '>', '&gt;' )
	return value
end

local function encodeXmlAttr( value )
	return ( string.gsub( encodeXmlText( value ), '"', '&quot;' ) )
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
	local o = {}
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
	self.__attr_names = {}

end

-- addAttribute(), attribute() and attributes() are XmlNode's, below


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
	self.__attr_names = {} -- in document order

end


function XmlNode:parent()
	return rawget( self, '__parent' )
end

function XmlNode:addAttribute( node )
	local name = node:name()
	if not self.__attrs[ name ] then
		tinsert( self.__attr_names, name )
	end
	self.__attrs[ name ] = node
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
	for _, name in ipairs( rawget( self, '__attr_names' ) ) do
		result:addNode( attrs[ name ] )
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


-- text of simple content, XML of complex content
function XmlNode:toString()
	if self:hasComplexContent() then
		return self:_childrenContent()
	end
	local func = function( val, node )
		return val .. node:toString()
	end
	return foldr( func, "", rawget( self, '__children' ) )
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
	local str_t = {}
	for _, name in ipairs( rawget( self, '__attr_names' ) ) do
		tinsert( str_t, attrs[ name ]:toXmlString() )
	end
	if #str_t > 0 then
		tinsert( str_t, 1, '' ) -- insert blank space
	end
	return tconcat( str_t, ' ' )
end


XmlDecNode.addAttribute = XmlNode.addAttribute
XmlDecNode.attribute = XmlNode.attribute
XmlDecNode.attributes = XmlNode.attributes


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
	return self.__name..'="'..encodeXmlAttr( self.__value )..'"'
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

-- a text node has no name, children or attributes, so a search
-- through mixed content passes over it
function XmlTextNode:name()
	return nil
end
function XmlTextNode:child( name )
	return XmlList()
end
function XmlTextNode:attribute( name )
	return XmlList()
end

function XmlTextNode:toString()
	return self.__text
end
function XmlTextNode:toXmlString()
	return encodeXmlText( self.__text )
end



--====================================================================--
-- XML Parser
--====================================================================--


-- https://github.com/PeterHickman/plxml/blob/master/plxml.lua
-- https://developer.coronalabs.com/code/simple-xml-parser
-- https://github.com/Cluain/Lua-Simple-XML-Parser/blob/master/xmlSimple.lua
-- http://lua-users.org/wiki/LuaXml

local XmlParser = {}

-- XML names: letters, digits, '_', ':', '.', '-' and any non-ASCII
-- byte (UTF-8), not starting with a digit, '.' or '-'
local NAME = '[%a_:\128-\255][%w_:%.%-\128-\255]*'

XmlParser.XML_NAME_RE = NAME
XmlParser.XML_DECLARATION_RE = '^%s*<%?xml%s+(.-)%?>'
XmlParser.XML_ATTR_RE = '('..NAME..')%s*=%s*(["\'])(.-)%2'


function XmlParser:decodeXmlString(value)
	return decodeXmlString(value)
end


-- used for the declaration, whose values have no '>'
function XmlParser:parseAttributes( node, attr_str )
	string.gsub(attr_str, XmlParser.XML_ATTR_RE, function( key, _, val )
		local attr = XmlAttrNode( {name=key, value=decodeXmlString(val)} )
		node:addAttribute( attr )
	end)
end


local function parseError( xml_str, pos, msg )
	error( string.format( "Lua E4X: %s, at character %d: '%s'",
		msg, pos, string.sub( xml_str, pos, pos+20 ) ), 0 )
end

local function findOrError( xml_str, str, pos, msg, err_pos )
	local si, ei = string.find( xml_str, str, pos, true )
	if not si then parseError( xml_str, err_pos, msg ) end
	return si, ei
end


-- reads the next piece of the XML at pos
-- returns kind, value, attributes, empty, next pos; nil at the end
-- kinds: 'text', 'cdata', 'skip' (comment, PI, DOCTYPE), 'start', 'end'
-- attributes of a start tag are a list of { name, value }
function XmlParser:_readToken( xml_str, pos )
	if pos > #xml_str then return nil end

	local lt = string.find( xml_str, '<', pos, true )
	if lt ~= pos then
		local stop = lt and lt-1 or #xml_str
		return 'text', string.sub( xml_str, pos, stop ), nil, nil, stop+1
	end

	local si, ei, name

	if string.sub( xml_str, pos, pos+3 ) == '<!--' then
		si, ei = findOrError( xml_str, '-->', pos+4, "comment isn't closed", pos )
		return 'skip', nil, nil, nil, ei+1

	elseif string.sub( xml_str, pos, pos+8 ) == '<![CDATA[' then
		si, ei = findOrError( xml_str, ']]>', pos+9, "CDATA isn't closed", pos )
		return 'cdata', string.sub( xml_str, pos+9, si-1 ), nil, nil, ei+1

	elseif string.sub( xml_str, pos, pos+1 ) == '<?' then
		si, ei = findOrError( xml_str, '?>', pos+2, "processing instruction isn't closed", pos )
		return 'skip', nil, nil, nil, ei+1

	elseif string.sub( xml_str, pos, pos+1 ) == '<!' then
		-- DOCTYPE, maybe with an internal subset in [ ]
		si = string.find( xml_str, '[%[>]', pos+2 )
		if si and string.sub( xml_str, si, si ) == '[' then
			si = findOrError( xml_str, ']', si+1, "DOCTYPE isn't closed", pos )
			si = string.find( xml_str, '>', si+1, true )
		end
		if not si then parseError( xml_str, pos, "DOCTYPE isn't closed" ) end
		return 'skip', nil, nil, nil, si+1

	elseif string.sub( xml_str, pos, pos+1 ) == '</' then
		si, ei, name = string.find( xml_str, '^</('..NAME..')%s*>', pos )
		if not si then parseError( xml_str, pos, "malformed end tag" ) end
		return 'end', name, nil, nil, ei+1

	end

	-- start tag, read attribute by attribute so a value may hold '>'
	si, ei, name = string.find( xml_str, '^<('..NAME..')', pos )
	if not si then parseError( xml_str, pos, "malformed tag" ) end

	local attrs = {}
	local p = ei+1
	local key, quote, vs, ve
	while true do
		si, ei = string.find( xml_str, '^%s*', p )
		p = ei+1
		if string.sub( xml_str, p, p+1 ) == '/>' then
			return 'start', name, attrs, true, p+2
		elseif string.sub( xml_str, p, p ) == '>' then
			return 'start', name, attrs, false, p+1
		end
		si, ei, key, quote = string.find( xml_str, '^('..NAME..')%s*=%s*(["\'])', p )
		if not si then parseError( xml_str, p, "malformed attribute in <"..name..">" ) end
		vs = ei+1
		ve = findOrError( xml_str, quote, vs, "attribute value isn't closed", p )
		tinsert( attrs, { key, decodeXmlString( string.sub( xml_str, vs, ve-1 ) ) } )
		p = ve+1
	end
end


local function addAttributes( node, attrs )
	for _, attr in ipairs( attrs ) do
		node:addAttribute( XmlAttrNode( {name=attr[1], value=attr[2]} ) )
	end
end


-- creates top-level Document Node
function XmlParser:parseString( xml_str )
	-- print( "XmlParser:parseString" )

	local root = XmlDocNode()
	local node
	local si, ei, attrs
	local kind, value, empty
	local pos = 1

	--== declaration

	si, ei, attrs = string.find(xml_str, XmlParser.XML_DECLARATION_RE, pos)

	if si then
		node = XmlDecNode()
		self:parseAttributes( node, attrs )
		root.declaration = node
		pos = ei + 1
	end

	--== comments, PIs, DOCTYPE, then the document root element

	while true do
		kind, value, attrs, empty, pos = self:_readToken( xml_str, pos )

		if kind == nil then
			error( "Lua E4X: no root element found", 0 )

		elseif kind == 'text' then
			if not string.find(value, "^%s*$") then
				root:addChild( XmlTextNode( {text=decodeXmlString(value)} ) )
			end

		elseif kind == 'start' then
			root:setName( value )
			addAttributes( root, attrs )
			if not empty then
				pos = self:_parseString( xml_str, root, pos )
			end
			break

		elseif kind ~= 'skip' then
			parseError( xml_str, pos, "malformed XML before the root element" )

		end
	end

	return root
end


-- recursive method
-- returns the position after the end tag of xml_node
--
function XmlParser:_parseString( xml_str, xml_node, pos )
	-- print( "XmlParser:_parseString", xml_node:name(), pos )

	local kind, value, attrs, empty
	local node

	while true do

		kind, value, attrs, empty, pos = self:_readToken( xml_str, pos )

		if kind == nil then
			error( "Lua E4X: missing end tag </"..xml_node:name()..">", 0 )

		elseif kind == 'text' then
			if not string.find(value, "^%s*$") then
				node = XmlTextNode( {text=decodeXmlString(value)} )
				xml_node:addChild( node )
			end

		elseif kind == 'cdata' then
			xml_node:addChild( XmlTextNode( {text=value} ) )

		elseif kind == 'start' then
			node = XmlNode( {name=value,parent=xml_node} )
			addAttributes( node, attrs )
			xml_node:addChild( node )
			if not empty then
				pos = self:_parseString( xml_str, node, pos )
			end

		elseif kind == 'end' then
			if value ~= xml_node:name() then
				error( "Lua E4X: incorrect closing label found: </"..value..">, expected </"..xml_node:name()..">", 0 )
			end
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
	save=save,

	__version=VERSION
}

--====================================================================--
-- lua_e4x.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_e4x.lua
--====================================================================--

--[[

Copyright (C) 2014 David McCuskey. All Rights Reserved.

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
-- DMC Lua Library : Lua E4X
--====================================================================--

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "0.1.0"



--====================================================================--
-- XML Classes
--====================================================================--

--====================================================================--
-- XML Node

local XmlNode = {}
XmlNode.__index = XmlNode

function XmlNode:new( ref )
	-- print("XmlNode:new")
	local obj = setmetatable( {}, XmlNode )
	obj._ref = ref
	return obj
end

-- name string or number
function XmlNode:child( value )
	-- print("XmlNode:child", value )
	local list = {}

	if type( value ) == 'string' then
		for i,v in ipairs( self._ref ) do
			-- print(i,v.label)
			if v.label == value then
				table.insert( list, XmlNode:new( v ) )
			end
		end

	end

	return list
end

function XmlNode:data()
	-- print("XmlNode:data")
	return self._ref[1]
end


--====================================================================--
-- XML Attribute

local XmlAttr = {}
XmlAttr.__index = XmlAttr



--====================================================================--
-- XML Parser
--====================================================================--

-- https://github.com/PeterHickman/plxml/blob/master/plxml.lua
-- https://developer.coronalabs.com/code/simple-xml-parser
-- https://github.com/Cluain/Lua-Simple-XML-Parser/blob/master/xmlSimple.lua
-- http://lua-users.org/wiki/LuaXml

local XmlParser = {}

XmlParser.XML_TAG_RE = '<(%/?)([%w:-]+)(.-)(%/?)>'
XmlParser.XML_ATTR_RE = "([%-_%w]+)=([\"'])(.-)%2"


function XmlParser:parseString( xml_str )
	-- print( "XmlParser:parseString" )
	local stack = {}
	local top = {}
	table.insert(stack, top)
	local ni, c, label, attrs, empty
	local i, j = 1, 1
	while true do
		ni,j,c,label,attrs,empty = string.find(xml_str, XmlParser.XML_TAG_RE, i)
		if not ni then break end
		local text = string.sub(xml_str, i, ni-1)
		if not string.find(text, "^%s*$") then
			table.insert(top, text)
		end
		if empty == "/" then  -- empty element tag
			table.insert(top, {label=label, attrs=self:parseAttributes(attrs), empty=1})
		elseif c == "" then   -- start tag
			top = {label=label, attrs=self:parseAttributes(attrs)}
			table.insert(stack, top)   -- new level
		else  -- end tag
			local toclose = table.remove(stack)  -- remove top
			top = stack[#stack]
			if #stack < 1 then
				error("nothing to close with "..label)
			end
			if toclose.label ~= label then
				error("trying to close "..toclose.label.." with "..label)
			end
			table.insert(top, toclose)
		end
		i = j+1
	end
	local text = string.sub(xml_str, i)
	if not string.find(text, "^%s*$") then
		table.insert(stack[#stack], text)
	end
	if #stack > 1 then
		error("unclosed "..stack[#stack].label)
	end
	return stack[1]
end

function XmlParser:parseAttributes( attr_str )
	local attrs = {}
	string.gsub(attr_str, XmlParser.XML_ATTR_RE, function (w, _, a)
		attrs[w] = a
	end)
	return attrs
end



--====================================================================--
-- Lua E4X API
--====================================================================--

local function parse( xml_str )
	-- print("LuaE4X.parse")
	local lua_tbl = XmlParser:parseString( xml_str )
	return XmlNode:new( lua_tbl[2] )
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
	load=load,
	parse=parse,
	save=save
}

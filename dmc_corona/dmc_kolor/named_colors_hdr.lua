--====================================================================--
--== Named Colors, deprecated alias
--====================================================================--

-- The X11 colors are kept in one file, named_colors_hex.lua; this name
-- loads that file, so configurations that use it keep working.
-- All color files give the same result: colors are translated to 0-1
-- values when they are loaded, whatever format a file is written in.

local name = ...
return require( ( name:gsub( 'named_colors_%a+$', 'named_colors_hex' ) ) )

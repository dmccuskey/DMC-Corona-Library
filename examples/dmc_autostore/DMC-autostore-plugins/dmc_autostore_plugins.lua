--===================================================================--
-- DMC AutoStore Plugin
--===================================================================--


local function encode( data )
	print("AutoStore Plugin: encoding data")
	return data
end

local function decode( data )
	print("AutoStore Plugin: decoding data")
	return data
end





--===================================================================--
-- Create Plugin Facade
--===================================================================--

local Plugins = {}

	Plugins.preSaveFunction = encode
	Plugins.postReadFunction = decode

return Plugins
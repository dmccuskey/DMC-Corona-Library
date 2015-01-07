--====================================================================--
-- dmc-wamp-authentication: App Config
--
-- for specific application configurations
--
--====================================================================--

--[[

All variables below are available to the application.

While this file is part of the file check-in, this can be and should be
edited by developers for use in their particular environment.
However, those changes are typically NOT checked in.

--]]



--====================================================================--
--== Setup, Constants


local user_1 = {
	id = 'joe',
	secret = 'secret2',
	ticket = 'secret!!!',
}

local user_2 = {
	id = 'peter',
	secret = 'prq7+YkJ1/KlW1X0YczMHw==',
	ticket = 'secret',
}


--====================================================================--
--== Config Exports
--====================================================================--


local Config = {}

Config.user = user_1
-- Config.user = user_2

Config.server = {
	host = 'ws://192.168.3.92/ws',
	port = 8080,
	realm = 'realm1',

	-- authmethods={ 'wampcra' },
	authmethods={ 'ticket', 'wampcra' },

	remote_procedure = 'com.example.add2'
}


return Config

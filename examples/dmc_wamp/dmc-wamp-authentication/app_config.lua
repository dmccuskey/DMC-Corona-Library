--====================================================================--
-- dmc-wamp-subscribe: App Config
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


local Config = {}

Config.user = {
	id = 'joe',
	secret = 'secret2',
	authmethods={ 'ticket', 'wampcra' }
}

Config.server = {
	host = 'ws://192.168.3.92',
	port = 8082,
	realm = 'realm1',

	sub_topic = 'com.myapp.topic1'
}


return Config

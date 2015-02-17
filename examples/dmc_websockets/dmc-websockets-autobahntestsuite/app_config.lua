local Config = {}

Config.app = {
	version = '1.0.0',
	build = '00',
}

Config.deployment = {
	-- 192.168.0.102, 192.168.3.120
	server_url = '192.168.3.84', -- or IP
	server_port = '9001',
	io_buffering_active = false
}

return Config

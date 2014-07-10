
-- test case array
--[[
{
	id='1.1.1',
	desc="echo empty message, clean close"
--]]
local test_cases = {

	--== 1.1 Framing, Text Msgs

	{ index='1', id='1.1.1', desc="echo empty message, clean close, normal code" },
	{ index='2', id='1.1.2', desc="echo message 125 bytes, clean close, normal code" },
	{ index='3', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },
	{ index='4', id='1.1.4', desc="echo message 127 bytes, clean close, normal code " },
	{ index='5', id='1.1.5', desc="echo message 128 bytes, clean close, normal code " },
	-- { index='6', id='1.1.6', desc="echo message 65535 bytes, clean close, normal code " },
	-- { index='7', id='1.1.7', desc="echo message 65536 bytes, clean close, normal code " },
	-- { index='8', id='1.1.8', desc="echo message 65536 bytes chopped, clean close, normal code " },


	--== 1.2 Framing, Binary Msgs

	{ index='9', id='2.1', desc="echo empty ping, clean close, normal code " },
	{ index='10', id='2.2', desc="echo ping, clean close, normal code " },
	{ index='11', id='2.3', desc="echo non-UTF8 ping, clean close, normal code " },
	-- { index='16', id='2.2', desc="echo message 126 bytes, clean close, normal code " },


	--== 2 Pings/Pongs

	-- { index='17', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },
	-- { index='27', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },


	--== 3 Reserved Bits

	-- { index='28', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },
	-- { index='34', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },


	--== 4.1 Opcodes, non-control

	-- { index='35', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },
	-- { index='39', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },


	--== 4.2 Opcodes, control

	-- { index='40', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },
	-- { index='44', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },


	--== 5 Fragmentation

	-- { index='45', id='5.1', desc="send ping fragmented into two fragments" },
	-- { index='46', id='5.2', desc="send pong fragmented into two fragments" },
	{ index='47', id='5.3', desc="echo message two fragments" },
	-- { index='64', id='1.1.3', desc="echo message 126 bytes, clean close, normal code " },


}


return test_cases

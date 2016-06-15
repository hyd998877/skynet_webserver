local skynet = require "skynet"
require "skynet.manager"
local snax = require "snax"

local cmd = {}

function cmd.login(header, data)
	if data.name == "admin" and data.pwd == "admin" then
		return "ok"
	end
	return "error"
end

function cmd.dump( header, data )
	local tmp = {}
	if header.host then
		table.insert(tmp, string.format("host: %s", header.host))
	end
	table.insert(tmp, "-----header----")
	for k,v in pairs(header) do
		table.insert(tmp, string.format("%s = %s",k,v))
	end
	return table.concat(tmp,"\n")
end

skynet.start(function()
	local handle = skynet.uniqueservice("webserver")
	
	skynet.call(handle, "lua", "register_url", "/login",{handle=skynet.self(), callback="login"})
	skynet.call(handle, "lua", "register_url", "/dump",{handle=skynet.self(), callback="dump"})
	
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(cmd[command])
		skynet.retpack(f(...))
	end)
end)
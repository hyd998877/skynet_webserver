local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local mimetypes = require 'mimetypes'
local table = table
local string = string

local mode = ...

if mode == "agent" then

local agent_url = {}
local agent_cmd = {}
local www = skynet.getenv("www")

local res_header = {}

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local function read_file( path )
	local filename = www .. path
	local file = io.open(filename, 'rb')
	if file then
		local value = file:read('*all')
		io.close(file)
		res_header["Content-Type"] = mimetypes.guess(filename or '')
		return value, header
	end
end

--[[
opt = {handle=skynet handle, callback=function call}
]]
function agent_cmd.register_url( url, opt )
	agent_url[url] = opt
end

function agent_cmd.request( id )
	socket.start(id)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
	if code then
		if code ~= 200 then
			response(id, code)
		else
			local tmp = {}
			local path, query = urllib.parse(url)
			if path == "/" then
				path = "/index.html"
			end
			local file_data = read_file(path)
			if file_data then
				response(id, code, file_data, res_header)
			else
				skynet.error("web server url:", path)
				local query_data = nil
				if query then
					query_data = urllib.parse_query(query)
				end
				local opt = agent_url[path]
				if opt then
					local response_data = skynet.call(opt.handle, "lua", opt.callback, header, query_data or body)
					response(id, code, response_data)
				else
					response(id, 404, "error 404")
				end
			end
		end
	else
		if url == sockethelper.socket_error then
			skynet.error("socket closed")
		else
			skynet.error(url)
		end
	end
	socket.close(id)
end

skynet.start(function()
	skynet.dispatch("lua", function (session, source, command, ...)
		local f = assert(agent_cmd[command])
		if session == 0 then
			f(...)
		else
			skynet.retpack(f(...))
		end
	end)
end)

else

local max_agent = 20
local cmd = {}
local agent = {}

function cmd.register_url( url, opt )
	for i=1,max_agent do
		skynet.call(agent[i], "lua", "register_url", url, opt)
	end
end

skynet.start(function()
	for i= 1, max_agent do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	local host = skynet.getenv("host") or "127.0.0.1"
	local port = tonumber(skynet.getenv("port")) or 8080
	local id = socket.listen(host, port)
	skynet.error("Listen web host "..host..":"..port)
	socket.start(id , function(id, addr)
		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", "request", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(cmd[command])
		skynet.retpack(f(...))
	end)
end)

end
local jsonServer = {}

if (sjson == nil) then sjson = cjson end

local onPost
local onGet

function jsonServer.on(type, cb)
    if (type:lower() == "post") then
        onPost = cb
    elseif (type:lower() == "get") then
        onGet = cb
    end
end

function jsonServer.sendJson(c, t)
    local json = sjson.encode(t)
    c:send("HTTP/1.0 200 OK\r\nContent-Length: "..string.len(json).."\r\nContent-Type: application/json\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n"..json)
end

function jsonServer.sendJsonOk(c)
    jsonServer.sendJson(c, { status="ok" })
end

function jsonServer.sendXml(c, f)
    jsonServer.sendFile(c, f, "text/xml")
end

function jsonServer.send404(c)
    c:send('HTTP/1.0 404 Not Found\r\nContent-Length: 21\r\nContent-Type: application/json\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n{"error":"not found"}')
end

function jsonServer.sendFile(c, f, m)
    local header = "HTTP/1.0 200 OK\r\nContent-Length: "..file.stat(f).size.."\r\nContent-Type: "..m.."\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
    local fi = file.open(f, "r")
    local d = fi:read()

    local function send(sk)
        if header ~= nil then 
          sk:send(header)
          header = nil
        elseif d ~= nil then
            sk:send(d)
            d = fi:read()
        else
          fi:close()
        end
    end
    
    c:on("sent", send)
    send(c)
end

local srv = net.createServer(net.TCP, 30)
srv:listen(80, function(conn)
  conn:on("receive", function(client, payload) 

    -- Inspired by https://github.com/marcoskirsch/nodemcu-httpserver/blob/master/httpserver.lua
    -- Some browsers send the POST data in multiple chunks.
    -- Collect data packets until the size of HTTP body meets the Content-Length stated in header
    if payload:find("Content%-Length:") or bBodyMissing then
        if fullPayload then fullPayload = fullPayload .. payload else fullPayload = payload end
        if (tonumber(string.match(fullPayload, "%d+", fullPayload:find("Content%-Length:")+16)) > #fullPayload:sub(fullPayload:find("\r\n\r\n", 1, true)+4, #fullPayload)) then
            bBodyMissing = true
            return
        else
            payload = fullPayload
            fullPayload, bBodyMissing = nil
        end
    end

    -- Header auswerten:
    if (bBodyMissing == nil) then
        local _, _, method, path, vars = payload:find("([A-Z]+) (.+)?(.+) HTTP")
        if (method == nil) then _, _, method, path = payload:find("([A-Z]+) (.+) HTTP") end

        if (method == "GET") then
            if (type(onGet) == "nil") then return end
            onGet(client, path:lower())
            return
        elseif (method == "POST") then
            if (type(onPost) == "nil") then return end
            -- Body hearausholen
            local _, headerEnd = payload:find("\r\n\r\n")
            local body = payload:sub(headerEnd + 1)
            onPost(client, path, sjson.decode(body))
        end
    end
  end)
end)

return jsonServer
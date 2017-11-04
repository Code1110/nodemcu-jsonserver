# JsonServer Lua Module for NodeMCU ESP8266

## Overview
This module aims to be a lightweight and easy to use http-server to for the ESP8266. If you need a fully fledged http-server, then use [nodemcu-httpserver](https://github.com/marcoskirsch/nodemcu-httpserver). It's original idea was to serve only JSON, but you can send any file with it. `Access-Control-Allow-Origin: *` is enabled, so you can use it in AJAX requests.

## Prequisites
This module is dependent on the following [NodeMCU](https://github.com/nodemcu/nodemcu-firmware) modules:
- net
- sjson

## Basic Example Code
```lua
jss = require("jsonServer")

jss.on("get", function(client, path)
    print("get path: "..path, node.heap())
    if (path == "/") then
        jss.sendFile(client, "index.html", "text/html")
    else if (path == "/getstate") then  -- path is alway lowercase!
        jss.sendJson(client, { device="button1", state=gpio.read(2) })
    else
        jss.send404(client)
    end
end)

jss.on("post", function(client, path, data)
    -- data is decoded JSON (and the request MUST be in JSON)
    print("post path: "..path, node.heap())
    jss.sendJsonOk(client)
    for k,v in pairs(data) do
        print(k,v)
    end
end)
```

## Events
### on(method, callback)
- `method`: Must be `get` or `post`.
- `callback`: A function that is called, when a GET or POST occours. The function takes the following arguments:
  - `client`: The client that made the request.
  - `path`: The requested path, always lowercase and with a leading slash (eg. `/getdata/2`).
  - `data`: Can only be used with POST. Contains the JSON decoded body of the request.

## Functions
### sendJson(client, json)
Sends the provided table serialized as JSON to the client.
- `client`: Client
- `json`: Lua table that will be serialized to JSON and send to the client.

**Examples**
```lua
jss.sendJson(client, { device="button1", state=gpio.read(2) } )
jss.sendJson(client, { chipid=string.format("%x",node.chipid()) } )
jss.sendJson(client, { { sensor=1, value=12.5 }, { sensor=2, value=25.7 } } )  -- nested table
jss.sendJson(client, dofile("nodeInfoModule.lua"))  -- the lua file should return a table
getTemperature(function(result) jss.sendJson(client, result) end)  -- can be used in a callback from anonther function
```

### sendFile(client, file, mimetype)
Sends the provided file to the client. The file is being sent in 1KB chuncks, so larger files can be send.
- `client`: Client
- `file`: The file to send.
- `mimetype`: Common mime types are: `text/plain`, `text/html`, `image/jpeg`, `image/png`.

**Examples**
```lua
jss.sendFile(client, "index.html", "text/html")
jss.sendFile(client, "test.jpg", "image/jpeg")
```

### sendJsonOk(client)
Sends a 200 to the client. This can be used to respond to POST requests. The body is in JSON and looks like this: `{"status":"ok"}`.

**Examples**
```lua
jss.sendJsonOk(client)
```

### send404(client)
Sends a 404 to the client. The body is in JSON and looks like this: `{"error":"not found"}`.

**Examples**
```lua
jss.send404(client)
```

### sendXml(client, xmlFile)
Sends the provided file as XML to the client.

**Examples**
```lua
jss.sendXml(client, "DeviceInfo.xml")
```

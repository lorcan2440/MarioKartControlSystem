local script_dir = debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]]

local gd_path = script_dir .. "Libraries/32-bit/gd.dll"
local socket_path = script_dir .. "Libraries/32-bit/socket"
local mime_path = script_dir .. "Libraries/32-bit/mime"

package.path = socket_path .. "/?.lua;" .. mime_path .. "/?.lua;"
package.cpath = socket_path .. "/?.dll;" .. mime_path .. "/?.dll;" .. gd_path

local gd = require("gd")
local socket = require("socket")
local mime = require("mime")

local host, port = "127.0.0.1", 12345
local client = assert(socket.connect(host, port))
client:settimeout(0.1)  -- set 100 ms timeout for non-blocking mode

OR, XOR, AND = 1, 3, 4

function bitoper(a, b, oper)
    -- source: https://stackoverflow.com/a/32389020/8747480
    local r, m, s = 0, 2^31
    repeat
        s, a, b = a + b + m, a % m, b % m
        r, m = r + m * oper % (s - a - b), m / 2
    until m < 1
    return r
end

function sendScreenshot()
    local screen = gui.gdscreenshot()
    local img = gd.createFromGdStr(screen)
    local pngData = img:pngStr()
    local dataLength = string.format("%09d", #pngData)
    client:send(dataLength)
    client:send(pngData)
end

function receiveButtons(client)
    local data, err = client:receive(1)  -- 1 byte from the Python script
    if data then
        local buttons = string.byte(data)
        -- decode the buttons
        -- A: 128, Left: 64, Right: 32, Unused: 16, 8, 4, 2, 1
        local A_press = bitoper(buttons, 128, AND) == 128
        local left_press = bitoper(buttons, 64, AND) == 64
        local right_press = bitoper(buttons, 32, AND) == 32
        local buttons_table = {A = A_press, left = left_press, right = right_press}
        joypad.set(1, buttons_table)
    else
        print("Error receiving data:", err)
    end
end

while not input.get().x do  -- press 'q' to stop streaming
    sendScreenshot()
    receiveButtons(client)
    emu.frameadvance()
end

client:close()
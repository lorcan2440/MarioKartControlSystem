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
client:settimeout(0.5)  -- set 500 ms timeout for non-blocking mode
print("Connected to the server: " .. host .. ":" .. port)

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
    local screen = gui.gdscreenshot{whichScreen="bottom"}
    local img = gd.createFromGdStr(screen)
    local pngData = img:pngStr()
    local dataLength = string.format("%09d", #pngData)
    client:send(dataLength)
    client:send(pngData)
end

function receiveButtons()
    local data, err = client:receive(1)  -- 1 byte from the Python script
    if data then
        local buttons = string.byte(data)
        -- decode the buttons
        -- A: 128, Left: 64, Right: 32, Unused: 16, 8, 4, 2, 1
        local A_press = bitoper(buttons, 128, AND) ~= 0
        local left_press = bitoper(buttons, 64, AND) ~= 0
        local right_press = bitoper(buttons, 32, AND) ~= 0
        -- only actively set left and right to pressed if they are  received
        -- this allows manual override while driving
        local buttons_table = {}
        if left_press then
            buttons_table = {A = A_press, left = left_press}
        elseif right_press then
            buttons_table = {A = A_press, right = right_press}
        else
            buttons_table = {A = A_press}
        end
        joypad.set(1, buttons_table)
        -- other useful functions for allowing manual override:
        -- joypad.get(), joypad.read(), joypad.peek(), joypad.set()
        -- can also request which buttons are 'only pressed' (down) or 'only released' (up)
    else
        -- socket is closed
        print("Error receiving data:", err)
        print("Disconnecting from server and pausing the game.")
        client:close()
        emu.pause()
    end
end

while not input.get().Q do  -- press key 'q' while on DeSmuME window to stop streaming
    sendScreenshot()
    receiveButtons()
    emu.frameadvance()
end

print("Quitting and disconnecting from the server.")
client:close()

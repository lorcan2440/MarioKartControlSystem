### How to Install Dependencies for `screenshot.lua` (32-bit, in DeSmuME environment)

1. Ensure you have the 32-bit version of `lua51.dll` in a directory added to PATH.
2. Obtain the `.lua` scripts for the `socket` and `mime` libraries [here](https://luarocks.org/modules/luasocket/luasocket/2.0.2-1). Download the file at the link titled [`win32-x86`](https://luarocks.org/manifests/luasocket/luasocket-2.0.2-1.win32-x86.rock). This file is an archive - use e.g. 7-zip to extract the contents, producing two directories: `lib` and `lua`.
3. The above contains 64-bit DLLs, but we want 32-bit DLLs, so go [here](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/bin/clibs/socket/core.dll) (socket) and [here](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/bin/clibs/mime/core.dll) (mime) to download the 32-bit versions of `core.dll` for `socket` and `mime` respectively. **Replace** the current versions of `core.dll` in the `lib` directories with these new 32-bit versions.
4. Obtain the `gd` library [here](https://downloads.onworks.net/softwaredownload.php?link=https%3A%2F%2Fdownloads.onworks.net%2Fdownloadapp%2FSOFTWARE%2Flua-gd-2.0.33r2-win32.zip%3Fservice%3Dservice01&filename=lua-gd-2.0.33r2-win32.zip). Extract all the `.dll` files: `free.type6.dll`, `gd.dll`, `jpeg62.dll`, `libgd2.dll`, `libiconv2.dll`, `libpng13.dll` into the same directory as the Lua engine DLL `lua51.dll`.
5. Re-organise the files of the other two directories (in Step 2) to produce the following structure:
6. ```
    .
    ├── socket/
        ├── socket/
            ├── core.dll
        ├── ftp.lua
        ├── http.lua
        ├── ltn12.lua
        ├── mime.lua
        ├── smtp.lua
        ├── socket.lua
        ├── tp.lua
        ├── url.lua
    ├── mime/
        ├── mime/
            ├── core.dll
    ├── free.type6.dll
    ├── gd.dll
    ├── jpeg62.dll
    ├── libgd2.dll
    ├── libiconv2.dll
    ├── libpng13.dll
    ├── lua51.dll
   ```
7. Inside `/socket/socket.lua`, on line 42, change `try = newtry()` to `try = socket.newtry()`.
8. In your own Lua script that you are using this for, import the modules.
    ```lua
    local gd_path = script_dir .. "path/to/gd.dll"
    local socket_path = script_dir .. "path/to/socket"
    local mime_path = script_dir .. "path/to/mime"

    package.path = socket_path .. "/?.lua;" .. mime_path .. "/?.lua;"
    package.cpath = socket_path .. "/?.dll;" .. mime_path .. "/?.dll;" .. gd_path

    local gd = require("gd")
    local socket = require("socket")
    local mime = require("mime")
    ```

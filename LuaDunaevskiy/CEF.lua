local script_name = 'UpdateIndexHTML'
local script_author = 'AlexDunaevskiy'
local script_version = '1.0.0'
local ffi = require 'ffi'
require 'moonloader'

function main()
    local file_path = getGameDirectory() .. "\\SAMP-RP\\CEF\\frontend\\index.html"
    local file = io.open(file_path, "r")
    if not file then
        print("Ошибка: Не удалось открыть index.html")
        return
    end
    
    local content = file:read("*a")
    file:close()
    local custom_script = 'src="./static/js/custom.js"'
    local custom_css = 'href="./static/css/custom.css"'
    
    if not content:find(custom_script, 1, true) or not content:find(custom_css, 1, true) then
        content = content:gsub('<html lang="en">', '<html lang="ru">')
        content = content:gsub(
            '(<script defer="defer" src="./static/js/main%.[^"]+%.js"></script>)',
            '%1\n    <script defer="defer" src="./static/js/custom.js"></script>'
        )
        content = content:gsub(
            '(<link href="./static/css/main%.[^"]+%.css" rel="stylesheet">)',
            '%1\n    <link href="./static/css/custom.css" rel="stylesheet">'
        )
        local file = io.open(file_path, "w")
        if file then
            file:write(content)
            file:close()
            sampAddChatMessage("[UpdateIndexHTML] index.html обновлен, перезапустите игру", 0x00FF00)
        else
            print("Ошибка: Не удалось записать в index.html")
        end
    else
        print("Строки уже присутствуют в index.html")
    end
end
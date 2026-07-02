local M = {}

-- 文字を%HEXに変換する
local char_to_hex = function(c)
    return string.format("%%%02X", string.byte(c))
end

-- %HEXを文字に変換する
local hex_to_char = function(x)
    return string.char(tonumber(x, 16))
end

-- URLエンコーダ
---@param str string
---@return string
function M.url_encode(str)
    if str == nil then return "" end

    str = string.gsub(str, "\n", "\r\n")
    -- text = string.gsub(text, "([^%w ])", char_to_hex)
    str = string.gsub(str, "([^%w %-%_%.%~])", char_to_hex)
    str = string.gsub(str, " ", "+")
    return str
end

-- URLデコーダ
---@param str string
---@return string
function M.url_decode(str)
    if str == nil then return "" end

    -- '+' を半角スペースに戻す
    str = string.gsub(str, "+", " ")

    -- %とそれに続く2文字の16進数を見つけてデコード
    str = string.gsub(str, "%%(%x%x)", hex_to_char)

    return str
end

return M

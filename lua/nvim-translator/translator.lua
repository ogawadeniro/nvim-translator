local M = {}
local ui = require('nvim-translator.ui')

-- 翻訳APIのリクエストパラメータ
---@class NTReqest
---@field src string
---@field dst string
---@field txt string

--- 指定できる言語のタイプ
---@alias TRANS_LANG @翻訳時に指定する言語のenum
---| "ja" Japanese
---| "en" English

-- 翻訳可能な最大文字数
---@type integer
TEXT_LEN_LIMIT = 3000

---@type fun(res_data: string): string?
M.parse_gemini_response = function(res_data)
    local parse_ok, parsed_data = pcall(vim.json.decode, res_data)
    if not parse_ok then
        return "翻訳結果のパースに失敗したよ"
    end
    if parsed_data.error then
        return "APIエラーが発生したよ。"
    end
    local translated_text = parsed_data.candidates[1].content.parts[1].text
    if not translated_text then
        return "翻訳結果の形式が想定と違ったよ"
    end
    return translated_text
end

-- 翻訳を実行する関数
---@param trans_req NTReqest
---@pram nt_config NTConfig
M.translate = function(trans_req, nt_config)
    -- apiクライアントを呼び出す
    local ok, api_client = pcall(require, "clients." .. nt_config.client.provider)
    if not ok then
        vim.notify("指定されたapiクライアントはサポート対象外です", vim.log.levels.ERROR, { title = "nvim-translator" })
        return
    end

    -- フローティングウィンドウを開いて一番上の行に移動
    ui.new()
    vim.cmd('noautocmd normal! gg0')

    -- ロードスピナーを表示する
    ui.draw_spinner({ "◐ now translating.", "☻ now translating..", "◑ now translating...", "◎ now translating" }, 1.5)

    -- apiを叩く
    api_client.hit(nt_config.client.opt, trans_req, ui)
end

return M

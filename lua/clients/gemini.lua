local http_helper = require("lib/http")
local async = require("lib/async")

local M = {}

-- -- 翻訳元テキストをフォーマットする関数(日本語)
-- ---@param text string @translated text
-- ---@return string[] @formatted text list
-- local format_text_ja = function(text)
--     -- split text from 。
--     local line_breaker = "。"
--     local formatted_text = vim.fn.split(text, line_breaker .. '\\s*\\zs')
--     -- local formatted_text = vim.fn.split(text, line_breaker)
--     return formatted_text
-- end
--
-- -- 翻訳元テキストをフォーマットする関数(英語)
-- ---@param text string @translated text
-- ---@return string[] @formatted text
-- local format_text_en = function(text)
--     local line_breaker = "\\."
--     local formatted_text = vim.fn.split(text, line_breaker .. '\\s*\\zs')
--     return formatted_text
-- end
--
-- local text_formatters = {
--     ja = format_text_ja,
--     en = format_text_en,
-- }

-- 翻訳後のテキストをフォーマットする関数
---@param text string
---@return string[] @formatted text
local function format_translated_texts(text)
    --フォーマット共通処理
    --連続した空白文字をスペース一つに置き換える。
    text = string.gsub(text, '%s+', ' ')
    return { text }

    -- -- 特定の言語に対するフォーマッタが見つからなかった場合、ここで終了。
    -- local text_formatter = text_formatters[language]
    -- if not text_formatter then
    --     return { text }
    -- end
    --
    -- -- 特定の言語に対するフォーマッタをかける
    -- local formatted_data = text_formatter(text)
    -- return formatted_data
end

---@return string
local function parse_response(res_data)
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

-- curl成功時の動作を定義
local on_success = function(ui, data) --成功時にスピナーを止める
    -- スピナーを止める
    local spinner = ui.get_spinner()
    if spinner and (not vim.loop.is_closing(spinner)) then
        spinner:close()
    end

    -- 生JSONをパースしてテキストだけを取り出す
    local parsed_data = parse_response(data)

    -- テキストをフォーマットして、画面に表示。
    local formatted_data = format_translated_texts(parsed_data)
    ui.overwrite_lines(formatted_data)
end

-- curl失敗時の動作を定義
local on_err = function(ui, data) --失敗時には失敗メッセージを表示する。
    -- スピナーを止める
    local spinner = ui.get_spinner()
    if spinner and (not vim.loop.is_closing(spinner)) then
        spinner:close()
    end
    ui.overwrite_lines("curlがエラーを返したよ\n" .. data)
end

-- APIで送信する翻訳リクエストデータを作成する。
---@type fun(trans_req: NTReqest): string
local create_req_data = function(trans_req)
    -- ソース文字数が制限を超えている場合はから文字列を返す
    if string.len(trans_req.txt) > TEXT_LEN_LIMIT then
        vim.notify("the text must be less than 3,000 characters", vim.log.levels.WARN)
        return ""
    end

    -- 改行をスペースに置き換え
    -- trans_req.txt = trans_req.txt:gsub("\r?\n", " ")

    -- 翻訳テキストをURLエンコードする
    trans_req.txt = http_helper.url_encode(trans_req.txt)

    -- リクエストデータ組み立て
    local prompt =
        "You are a professional translator. Translate the user's input from " ..
        trans_req.src ..
        " to " ..
        trans_req.dst ..
        ". Output ONLY the final translated text. Do not include any greeting, explanation, or markdown formatting."

    local payload = {
        systemInstruction = {
            parts = { { text = prompt } }
        },
        contents = {
            parts = { { text = trans_req.txt } }
        },
        generationConfig = {
            temperature = 0.3
        }
    }
    local req_data = vim.json.encode(payload)
    return req_data
end

function M.hit(client_opt, trans_req, ui)
    -- curlのリクエストデータ作成
    local req_data = create_req_data(trans_req)
    -- curlコマンド定義
    local cmd_list = {
        ["curl"] = {
            "-s", "-X", "POST", client_opt.url,
            "-H", "x-goog-api-key: " .. client_opt.api_key,
            "-H", "Content-Type: application/json",
            "-d", req_data
        }
    }
    -- curlコマンドを叩く
    for cmd, args in pairs(cmd_list) do
        if vim.fn.executable(cmd) == 1 then
            async.execute_cmd_async(
                cmd,
                args,
                function(data) on_success(ui, data) end,
                function(data) on_err(ui, data) end)
            return
        end
    end
end

return M

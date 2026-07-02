local http_helper = require("lib/http")
local async = require("lib/async")

local M = {}

-- 翻訳後のテキストをフォーマットする関数
---@param text string
---@return string[] @formatted text
local function format_translated_texts(text)
    --フォーマット共通処理
    --連続した空白文字をスペース一つに置き換える。
    text = string.gsub(text, '%s+', ' ')
    --URLをデコードする
    text = http_helper.url_decode(text)
    --改行区切りで配列に挿入
    local lines = {}
    for line in string.gmatch(text, "[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

---レスポンスのJSONをパースする
---@return string
local function parse_response(res_data)
    -- JSONパース失敗時
    local parse_ok, parsed_data = pcall(vim.json.decode, res_data)
    if not parse_ok then
        return "翻訳結果のパースに失敗したよ"
    end

    -- APIエラー時
    if parsed_data.message then
        return parsed_data.message
    end

    -- 成功レスポンス例
    -- {
    --   "translations": [
    --     {
    --       "detected_source_language": "EN",
    --       "text": "こんにちは、世界！"
    --     }
    --   ]
    -- }
    local translated_text = parsed_data.translations[1].text
    if not translated_text then
        return "翻訳結果の形式が想定と違ったよ"
    end

    -- API成功時
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
    ui.overwrite_lines({ "curlがエラーを返したよ", (data or "エラー出力なし") })
end

-- APIで送信する翻訳リクエストデータを作成する。
---@type fun(trans_req: NTReqest): string, string?
local create_req_data = function(trans_req)
    -- ソース文字数が制限を超えている場合はから文字列を返す
    if string.len(trans_req.txt) > TEXT_LEN_LIMIT then
        return "", "翻訳元の文字数が多すぎるよ"
    end

    -- 改行をスペースに置き換え
    trans_req.txt = trans_req.txt:gsub("\r?\n", " ")

    -- 翻訳テキストをURLエンコードする
    trans_req.txt = http_helper.url_encode(trans_req.txt)

    trans_req.dst = string.upper(trans_req.dst)

    -- jsonペイロードとしてjson文字列を返す
    local payload = {
        text = { trans_req.txt },
        target_lang = trans_req.dst
    }
    local req_data = vim.json.encode(payload)

    return req_data
end

function M.hit(client_opt, trans_req, ui)
    -- curlのリクエストデータ作成
    local req_data, err = create_req_data(trans_req)
    if err then
        ui.overwrite_lines({ err })
        return
    end

    -- curlコマンド定義
    local cmd_list = {
        ["curl"] = {
            "-s", "-X", "POST", client_opt.url,
            "-H", "Content-Type: application/json",
            "-H", "Authorization: DeepL-Auth-Key " .. client_opt.api_key,
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

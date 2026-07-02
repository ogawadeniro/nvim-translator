local M = {}
local ui = require('nvim-translator.ui')

-- 翻訳APIのリクエストパラメータ
---@class NTReqest
---@field src string
---@field dst string
---@field txt string

--- 指定できる言語のタイプ
---@alias TRANS_LANG @翻訳時に指定する言語のenum
---| "ace" Acehnese
---| "af" Afrikaans
---| "sq" Albanian
---| "ar" Arabic
---| "an" Aragonese
---| "hy" Armenian
---| "as" Assamese
---| "ay" Aymara
---| "az" Azerbaijani
---| "ba" Bashkir
---| "eu" Basque
---| "be" Belarusian
---| "bn" Bengali
---| "bho" Bhojpuri
---| "bs" Bosnian
---| "br" Breton
---| "bg" Bulgarian
---| "my" Burmese
---| "yue" Cantonese
---| "ca" Catalan
---| "ceb" Cebuano
---| "zh"-hans Chinese (simplified)
---| "zh"-hant Chinese (traditional)
---| "zh" Chinese (unspecified variant)
---| "hr" Croatian
---| "cs" Czech
---| "da" Danish
---| "prs" Dari
---| "nl" Dutch
---| "en" English (all variants)
---| "en"-us English (American)
---| "en"-gb English (British)
---| "eo" Esperanto
---| "et" Estonian
---| "fi" Finnish
---| "fr" French
---| "fr"-ca French (Canadian)
---| "gl" Galician
---| "ka" Georgian
---| "de" German
---| "de"-ch German (Swiss)
---| "el" Greek
---| "gn" Guarani
---| "gu" Gujarati
---| "ht" Haitian Creole
---| "ha" Hausa
---| "he" Hebrew
---| "hi" Hindi
---| "hu" Hungarian
---| "is" Icelandic
---| "ig" Igbo
---| "id" Indonesian
---| "ga" Irish
---| "it" Italian
---| "ja" Japanese
---| "jv" Javanese
---| "pam" Kapampangan
---| "kk" Kazakh
---| "gom" Konkani
---| "ko" Korean
---| "kmr" Kurdish (Kurmanji)
---| "ckb" Kurdish (Sorani)
---| "ky" Kyrgyz
---| "la" Latin
---| "lv" Latvian
---| "ln" Lingala
---| "lt" Lithuanian
---| "lmo" Lombard
---| "lb" Luxembourgish
---| "mk" Macedonian
---| "mai" Maithili
---| "mg" Malagasy
---| "ms" Malay
---| "ml" Malayalam
---| "mt" Maltese
---| "mi" Maori
---| "mr" Marathi
---| "mn" Mongolian
---| "ne" Nepali
---| "nb" Norwegian Bokmål
---| "oc" Occitan
---| "om" Oromo
---| "pag" Pangasinan
---| "ps" Pashto
---| "fa" Persian
---| "pl" Polish
---| "pt"-br Portuguese (Brazilian)
---| "pt"-pt Portuguese (European)
---| "pt" Portuguese (unspecified variant)
---| "pa" Punjabi
---| "qu" Quechua
---| "ro" Romanian
---| "ru" Russian
---| "sa" Sanskrit
---| "sr" Serbian
---| "st" Sesotho
---| "scn" Sicilian
---| "sk" Slovak
---| "sl" Slovenian
---| "es" Spanish
---| "es"-419 Spanish (Latin American)
---| "su" Sundanese
---| "sw" Swahili
---| "sv" Swedish
---| "tl" Tagalog
---| "tg" Tajik
---| "ta" Tamil
---| "tt" Tatar
---| "te" Telugu
---| "th" Thai
---| "ts" Tsonga
---| "tn" Tswana
---| "tr" Turkish
---| "tk" Turkmen
---| "uk" Ukrainian
---| "ur" Urdu
---| "uz" Uzbek
---| "vi" Vietnamese
---| "cy" Welsh
---| "wo" Wolof
---| "xh" Xhosa
---| "yi" Yiddish
---| "zu" Zulu

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
---@param nt_config NTConfig
M.translate = function(trans_req, nt_config)
    -- apiクライアントを呼び出す
    local ok, api_client = pcall(require, "clients." .. nt_config.client.provider)
    if not ok then
        vim.notify("指定されたapiクライアントはサポート対象外です", vim.log.levels.ERROR, { title = "nvim-translator" })
        return
    end

    -- フローティングウィンドウを開いて一番上の行に移動
    local title =
        " 󰗊  "
        .. trans_req.src .. " " .. trans_req.dst .. " "
        .. nt_config.client.provider
        .. " "
    ui.new(title)
    vim.cmd('noautocmd normal! gg0')

    -- ロードスピナーを表示する
    ui.draw_spinner({
            -- "  now translating ",
            -- "  now translating ",
            -- "  now translating ",
            -- "  now translating ",
            -- "  now translating ",
            -- "  now translating ",
            " now translating ▂▄▅",
            " now translating ▆▅▃",
            " now translating ▃▇▅",
        },
        1.0
    )

    -- apiを叩く
    api_client.hit(nt_config.client.opt, trans_req, ui)
end

return M

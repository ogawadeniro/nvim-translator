local M = {}

-- モジュールをインポート
local nt_config = require('nvim-translator.config')
local translator = require('nvim-translator.translator')

-- visualモードで選択したテキストを取得する関数
---@type fun(): string
local get_selected_text = function()
    local zreg_bf = vim.fn.getreg("z")
    vim.cmd('noautocmd normal! "zy')
    local zreg_af = vim.fn.getreg("z")
    vim.fn.setreg("z", zreg_bf)
    return zreg_af
end

-- カーソル下の単語を取得する関数
---@type fun(): string
local get_cursor_text = function()
    local zreg_bf = vim.fn.getreg("z")
    vim.cmd('noautocmd normal! viw"zy')
    local zreg_af = vim.fn.getreg("z")
    vim.fn.setreg("z", zreg_bf)
    return zreg_af
end

local text_loaders = {
    visual = get_selected_text,
    cursor = get_cursor_text
}

-- 翻訳元テキストを取得する関数
---@param type "visual"|"cursor"
---@return string
local get_src_text = function(type)
    local text_loader = text_loaders[type]
    local text = text_loader()
    return text
end

---@param user_config NTConfig?
function M.setup(user_config)
    -- コンフィグをビルド
    nt_config.build_config(user_config)
    nt_config = nt_config.get()

    -- keymapを設定
    local keymaps = nt_config.keymap
    for i = 1, #keymaps do
        vim.api.nvim_set_keymap("v", keymaps[i].key, "", {
            callback = function()
                local txt = get_src_text("visual")
                local trans_req = {
                    txt = txt,
                    src = keymaps[i].src,
                    dst = keymaps[i].dst
                }
                translator.translate(trans_req, nt_config)
            end,
        })
    end
end

return M

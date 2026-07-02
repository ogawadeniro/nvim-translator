local M = {}

-- keymap configuration type
---@class NTKeymapConfig
---@field src TRANS_LANG
---@field dst TRANS_LANG
---@field key string

---@class NTClientConfig
---@field provider string
---@field opt NTClientConfigOpt

---@class NTClientConfigOpt
---@field url string?
---@field api_key string?

---@class NTConfig
---@field keymap NTKeymapConfig[]?
---@field client NTClientConfig
local config = {
    keymap = {
        {
            key = "<Leader>?",
            src = "en",
            dst = "ja",
        },
        {
            key = "<Leader>g?",
            src = "ja",
            dst = "en",
        }
    },
    client = {
        provider = "",
        opt = {}
    }
}

-- 設定をビルドする関数
---@type fun(user_config: NTConfig?)
function M.build_config(user_config)
    config = vim.tbl_deep_extend("force", config, user_config)
end

function M.get()
    return config
end

return M

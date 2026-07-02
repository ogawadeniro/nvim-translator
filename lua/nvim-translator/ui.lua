local FloatWindow = require('lib.float_window')

local M = {}

---@type FloatWindow
local float_window = FloatWindow.new()
local uv = vim.loop
local spinner = uv.new_timer()

---@type fun():nil
function M.new()
    -- floatwindow configuration
    local config_win = {
        focusable = true,
        width     = 100,
        height    = 10,
        --         col       = vim.opt.columns:get() - width - border_off - offset,
        --         row       = vim.opt.lines:get() - height - border_off - offset - 1,
        col       = 1,
        row       = 1,
        border    = {
            "╭", "─", "╮", "│",
            "╯", "─", "╰", "│"
        },
        style     = 'minimal',
        relative  = "cursor",
        anchor    = "NW",
        title     = " nvim-translator ",
    }
    local config_keymaps = {
        {
            is_buf = true,
            mode = "n",
            lhs = "q",
            rhs = "",
            opts = {
                noremap = true,
                callback = function()
                    float_window.close_win()
                end,
            },
        },
        {
            is_buf = true,
            mode = "n",
            lhs = "j",
            rhs = "gj",
            opts = {
                noremap = true,
            },
        },
        {
            is_buf = true,
            mode = "n",
            lhs = "k",
            rhs = "gk",
            opts = {
                noremap = true,
            },
        },
        {
            is_buf = true,
            mode = "n",
            lhs = "<C-a>",
            rhs = "",
            opts = {
                noremap = true,
                callback = function()
                    vim.cmd("noautocmd normal! ggyG")
                    vim.notify("翻訳結果をコピーしたよ", vim.log.levels.INFO, { title = "nvim-translator" })
                end
            },
        },
    }
    local options = {
        win = {
            {
                name = "wrap",
                value = true,
            }
        },
        buf = {
        },
        hl = {
            -- {
            -- name = "NormalFloat",
            -- value = {
            -- fg = "#fefefe",
            -- bg = "#343934",
            -- }
            -- },
            -- {
            -- name = "FloatBorder",
            -- value = {
            -- fg = "#fefefe",
            -- bg = "none",
            -- }
            -- },
        },
    }

    ---@type FWinConfig
    local config = {
        name = "nvim-translator",
        window = config_win,
        keymaps = config_keymaps,
        options = options,
        autocmd = {}
    }

    float_window.init(config)
    M.overwrite_lines({ "" })
end

---@param lines string[]
---@return nil
function M.overwrite_lines(lines)
    float_window.write_lines(0, -1, lines)
end

function M.add_keymap(keymaps)
end

function M.resize(row, col, width, height)
end

---@param spin_chars string[]
---@param spin_interval integer * 100msec
function M.draw_spinner(spin_chars, spin_interval)
    spinner = uv.new_timer()
    local spin_cnt = 0

    local cb = vim.schedule_wrap(function()
        if (#vim.fn.win_findbuf(float_window.bufnr) < 1) and (spinner ~= nil) and (not uv.is_closing(spinner)) then
            spinner:close()
        end
        M.overwrite_lines({ spin_chars[spin_cnt % #spin_chars + 1] })
        spin_cnt = spin_cnt + 1
    end)
    ---@cast spinner uv.uv_timer_t
    uv.timer_start(spinner, 0, spin_interval * 100, cb)
end

---@return uv.uv_timer_t?
function M.get_spinner()
    return spinner
end

return M

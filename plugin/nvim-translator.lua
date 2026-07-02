-- duplication check
if vim.g.loaded_nvim_translator then
    return
end
vim.g.loaded_nvim_translator = true

-- nvim check
if vim.fn.has('nvim') ~= 1 then
    vim.notify("this plugin only support nvim.", vim.log.levels.ERROR)
    return
end

-- nvim version check (support >= nvim 0.10.0)
---@type (vim.Version)?
local nvim_local_v = vim.version.parse(vim.fn.system({ 'nvim', '-v' }), { strict = false })
local nvim_support_v = { 0, 9, 0 }
if (nvim_local_v ~= nil) and (vim.version.lt(nvim_local_v, nvim_support_v)) then
    vim.notify(
        "[nvim-translator] this plugin only support nvim version >="
        .. nvim_support_v[1] .. "." .. nvim_support_v[2] .. "." .. nvim_support_v[3]
        .. "\nI won't know it works unless you try it",
        vim.log.levels.WARN
    )
end

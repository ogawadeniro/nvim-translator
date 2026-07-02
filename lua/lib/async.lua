local M = {}

M.execute_cmd_async = function(cmd, cmd_args, on_cmd_success, on_cmd_err)
    local response_chunks = {}

    vim.fn.jobstart({ cmd, unpack(cmd_args) }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if data then
                table.insert(response_chunks, table.concat(data, "\n"))
            end
        end,

        -- 通信が終わったタイミングで実行される関数
        on_exit = function(_, exit_code)
            -- 【チェック1】curl自体の通信が成功したか (0なら通信成功)
            if exit_code ~= 0 then
                vim.schedule(on_cmd_err)
                vim.notify(cmd .. "での通信に失敗したよ", vim.log.levels.ERROR)
                return
            end

            -- レスポンスの結合とJSONデコード
            local raw_json = table.concat(response_chunks, "")
            vim.schedule(function() on_cmd_success(raw_json) end)
        end
    })
end

---@type fun(cmd: string, cmd_args: string[], on_cmd_success: function, on_cmd_err: function)
M._execute_cmd_async = function(cmd, cmd_args, on_cmd_success, on_cmd_err)
    if not vim.fn.executable(cmd) then
        vim.notify(cmd .. " is not executable", vim.log.levels.ERROR)
        return
    end
    local luv = vim.loop --vim.uv

    local stdout_pipe = luv.new_pipe()
    local stderr_pipe = luv.new_pipe()
    local options = {
        args = cmd_args,
        stdio = { nil, stdout_pipe, stderr_pipe }
    }

    local handle
    -- callback function called on exit asynchronous process
    local on_exit = function(_)
        luv.read_stop(stdout_pipe)
        luv.read_stop(stderr_pipe)
        luv.close(stdout_pipe)
        luv.close(stderr_pipe)
        if handle ~= nil then luv.close(handle) end
    end
    -- callback function called on success.
    local on_success = luv.new_async(vim.schedule_wrap(on_cmd_success))
    -- callback function called on error.
    local on_err = luv.new_async(vim.schedule_wrap(on_cmd_err))

    -- spawn proceess
    handle = luv.spawn(cmd, options, on_exit)
    if handle == nil then
        vim.notify("can not open procceess.", vim.log.levels.ERROR)
        return
    end

    -- read stdout
    luv.read_start(stdout_pipe, vim.schedule_wrap(function(_, data) -- status, data
        if data then
            if on_success ~= nil then
                luv.async_send(on_success, data)
            end
        end
    end))
    -- read stderr
    luv.read_start(stderr_pipe, vim.schedule_wrap(function(_, data) -- status, data
        if data then
            if on_err ~= nil then
                luv.async_send(on_err, data)
            end
        end
    end))
end

return M

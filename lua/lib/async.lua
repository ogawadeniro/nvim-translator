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

return M

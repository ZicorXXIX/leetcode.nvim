local function show_wrong_answer_window()
    local buf = vim.api.nvim_create_buf(false, true) -- Create a scratch buffer

    -- Define text content
    local lines = {
        " Wrong Answer | Runtime 1 ms ",  -- Single-line message
        "",
        "Expected: 42",
        "Got: 43"
    }

    -- Set buffer lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Create floating window
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")
    local win_width = 50
    local win_height = #lines + 2
    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Results ",
        title_pos = "center"
    })

    -- Define Highlights
    vim.api.nvim_set_hl(0, "ErrorText", { fg = "red", bold = true })
    vim.api.nvim_set_hl(0, "InfoText", { fg = "grey" })

    -- Apply Highlights for "Wrong Answer" and "Runtime" separately
    local line_content = lines[1]
    local wrong_answer_start = string.find(line_content, "Wrong Answer")
    local runtime_start = string.find(line_content, "| Runtime")

    if wrong_answer_start then
        vim.api.nvim_buf_add_highlight(buf, 0, "ErrorText", 0, wrong_answer_start - 1, runtime_start - 2) -- "Wrong Answer" in red
    end

    if runtime_start then
        vim.api.nvim_buf_add_highlight(buf, 0, "InfoText", 0, runtime_start - 1, -1) -- "| Runtime 1 ms" in grey
    end
end

-- Call the function to test
show_wrong_answer_window()


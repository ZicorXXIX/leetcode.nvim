local function open_quote_window()
    -- Create a new scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Define block quote content
    local quote_lines = {
        "│ Block quotes are used to highlight text.
         V│
    }
    
    -- Set the buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, quote_lines)

    -- Get editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")
    
    -- Window dimensions
    local win_width = 50
    local win_height = 3
    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    -- Open floating window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    -- Apply highlights
    local ns_id = vim.api.nvim_create_namespace("blockquote")
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Comment", 0, 0, 1) -- Gray for `│`
    vim.api.nvim_buf_add_highlight(buf, ns_id, "Normal", 0, 2, -1) -- Normal text
end

-- Call the function
open_quote_window()

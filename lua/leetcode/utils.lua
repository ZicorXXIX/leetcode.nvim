
local utils = {}

utils.create_file = function(slug, codeSnippets)
    local bufnr = vim.api.nvim_create_buf(false, true)

    -- Set up terminal options
    vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)

    -- Create window configuration
    local opts = {
        -- relative = 'editor',
        -- width = 40,
        -- height = 20,
        -- col = 0,           -- Leftmost position
        -- row = 0,
        split = 'left',
        win = 0

        -- anchor = "W",      -- Changed from 'W' to "W"
        -- style = 'vertical',
        -- focusable = true,
        -- border = 'rounded'
    }

    -- Open window 
    -- Parameters: ~
    --   • {buffer}  Buffer to display, or 0 for current buffer
    --   • {enter}   Enter the window (make it the current window)
    --   • {config}  Map defining the window configuration. Keys:
    local winnr = vim.api.nvim_open_win(bufnr, false, opts)

    -- Configure terminal settings
    vim.api.nvim_buf_set_name(bufnr, "terminal://" .. vim.fn.getcwd())

    -- Enter terminal mode and setup prompt
    vim.api.nvim_buf_call(bufnr, function()
        -- Start terminal
        vim.cmd.startinsert()

        -- Add slug content
        local lines = vim.split(slug, "\n", { plain = true })
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

        -- Move cursor to end
        vim.cmd([[normal! G]])
    end)
    local bufnr = vim.fn.bufadd("filename.cpp")
    vim.fn.bufload(bufnr)

    -- Ensure it's a normal file buffer
    vim.api.nvim_buf_set_option(bufnr, "buftype", "")

    -- Write "hello world" to the buffer
    local lines = {}
    for line in codeSnippets[1].code:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    vim.api.nvim_set_current_buf(bufnr)
end

utils.submit = function()
  local buffer = vim.api.nvim_get_current_buf()
  print(buffer)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true) 
  print(table.concat(lines, "\n"))
end


return utils

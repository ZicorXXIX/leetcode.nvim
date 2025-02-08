local utils = {}

utils.create_file = function(slug)
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
end

return utils

local utils = {}

-- Import custom highlight functions
local custom_highlight = require("leetcode.custom_highlight")

utils.create_file = function(content, codeSnippets)
    -- Create markdown buffer
    local markdown_bufnr = vim.api.nvim_create_buf(false, true)

    -- Set up buffer options
    vim.api.nvim_buf_set_option(markdown_bufnr, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(markdown_bufnr, 'swapfile', false)
    vim.api.nvim_buf_set_option(markdown_bufnr, 'modifiable', false)
    vim.api.nvim_buf_set_option(markdown_bufnr, 'readonly', true)
    vim.api.nvim_buf_set_option(markdown_bufnr, 'number', false)
    vim.api.nvim_buf_set_option(markdown_bufnr, 'relativenumber', false)
    vim.api.nvim_buf_set_option(markdown_bufnr, 'signcolumn', 'no')
    vim.api.nvim_buf_set_option(markdown_bufnr, 'foldcolumn', '0')

    -- Create a vertical split
    vim.cmd('vsplit')
    
    -- Get the window ID of the new split
    local winnr = vim.api.nvim_get_current_win()
    
    -- Set the buffer in the window
    vim.api.nvim_win_set_buf(winnr, markdown_bufnr)
    
    -- Set window width to 50% of total width
    local width = math.floor(vim.o.columns * 0.5)
    vim.api.nvim_win_set_width(winnr, width)

    -- Set window-local options for wrapping
    vim.wo[winnr].wrap = true
    vim.wo[winnr].linebreak = true
    vim.wo[winnr].breakindent = true
    vim.wo[winnr].breakindentopt = 'shift:2'

    -- Configure buffer settings with markdown content
    vim.api.nvim_buf_set_name(markdown_bufnr, "leetcode://problem")
    vim.api.nvim_buf_set_option(markdown_bufnr, 'filetype', 'html')

    -- Process and set content with custom highlighting
    vim.api.nvim_buf_call(markdown_bufnr, function()
        vim.api.nvim_buf_set_option(markdown_bufnr, 'modifiable', true)
        local processed = custom_highlight.ProcessHTMLContent(content)
        vim.api.nvim_buf_set_lines(markdown_bufnr, 0, -1, false, vim.split(processed.text, '\n'))
        vim.api.nvim_buf_set_option(markdown_bufnr, 'modifiable', false)
        
        -- Apply custom highlights
        custom_highlight.DefineCustomHighlights()
        custom_highlight.ApplyCustomHighlights(markdown_bufnr, processed.highlights)
    end)

    -- Create and load the second buffer for cpp content
    local cpp_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(cpp_bufnr, "leetcode://solution.cpp")

    -- Set up second buffer options
    vim.api.nvim_buf_set_option(cpp_bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(cpp_bufnr, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(cpp_bufnr, "swapfile", false)
    vim.api.nvim_buf_set_option(cpp_bufnr, 'modifiable', true)
    vim.api.nvim_buf_set_option(cpp_bufnr, 'filetype', 'cpp')

    -- Set cpp content with syntax highlighting
    local cpp_lines = {}
    for line in codeSnippets[1].code:gmatch("([^\n]*)\n?") do
        table.insert(cpp_lines, line)
    end
    vim.api.nvim_buf_set_lines(cpp_bufnr, 0, -1, false, cpp_lines)

    -- Move to the rightmost window and set the cpp buffer
    vim.cmd('wincmd l')
    vim.api.nvim_set_current_buf(cpp_bufnr)
end

return utils

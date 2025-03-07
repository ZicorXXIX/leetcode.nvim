
local utils = {}

utils.create_file = function(slug, codeSnippets)
    local markdown_bufnr = vim.api.nvim_create_buf(false, true)

    -- Set up buffer options
    vim.api.nvim_buf_set_option(markdown_bufnr, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(markdown_bufnr, 'swapfile', false)
    vim.api.nvim_buf_set_option(markdown_bufnr, 'modifiable', false)
    vim.api.nvim_buf_set_option(markdown_bufnr, 'readonly', true)

    -- Create window configuration
    local opts = {
        split = 'left',
        win = 0
    }

    -- Open window with the first buffer
    local winnr = vim.api.nvim_open_win(markdown_bufnr, false, opts)

    -- Configure buffer settings with markdown content
    vim.api.nvim_buf_set_name(markdown_bufnr, "terminal://" .. vim.fn.getcwd())
    vim.api.nvim_buf_set_option(markdown_bufnr, 'filetype', 'html')

    -- Set markdown content (slug)
    vim.api.nvim_buf_call(markdown_bufnr, function()
        vim.api.nvim_buf_set_option(markdown_bufnr, 'modifiable', true)
        local markdown_lines = vim.split(slug, "\n", { plain = true })
        vim.api.nvim_buf_set_lines(markdown_bufnr, 0, -1, false, markdown_lines)
        vim.api.nvim_buf_set_option(markdown_bufnr, 'modifiable', false)
    end)

    -- Force Markview to render by making it current temporarily
    vim.api.nvim_set_current_buf(markdown_bufnr)

    -- Create and load the second buffer for cpp content
    local cpp_bufnr = vim.fn.bufadd("filename.cpp")
    vim.fn.bufload(cpp_bufnr)

    -- Set up second buffer options
    vim.api.nvim_buf_set_option(cpp_bufnr, "buftype", "")
    vim.api.nvim_buf_set_option(cpp_bufnr, 'modifiable', false)
    vim.api.nvim_buf_set_option(cpp_bufnr, 'readonly', true)
    vim.api.nvim_buf_set_option(cpp_bufnr, 'filetype', 'cpp')

    -- Set cpp content (codeSnippets[1].code)
    vim.api.nvim_buf_set_option(cpp_bufnr, 'modifiable', true)
    local cpp_lines = {}
    for line in codeSnippets[1].code:gmatch("([^\n]*)\n?") do
        table.insert(cpp_lines, line)
    end
    vim.api.nvim_buf_set_lines(cpp_bufnr, 0, -1, false, cpp_lines)
    vim.api.nvim_buf_set_option(cpp_bufnr, 'modifiable', false)

    -- Set the cpp buffer as current
    vim.api.nvim_set_current_buf(cpp_bufnr)
end


return utils

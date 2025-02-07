local utils = {}

utils.create_file = function(slug)
    -- Define the file path
    local file_path = vim.fn.expand("~/Desktop/newfile.txt")

    -- Split the slug into lines
    local lines = vim.split(slug, "\n", { plain = true })

    -- Create or open the file in a new buffer
    local buf = vim.fn.bufadd(file_path)
    vim.fn.bufload(buf) -- Load the buffer
    vim.api.nvim_buf_set_option(buf, "buftype", "") -- Ensure it's a normal file buffer

    -- Set the content of the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Save the buffer to the file
    vim.api.nvim_buf_call(buf, function()
        vim.cmd("w") -- Write the buffer to the file
    end)

    -- Optionally, close the buffer after saving
    vim.api.nvim_buf_delete(buf, { force = true })
end

return utils

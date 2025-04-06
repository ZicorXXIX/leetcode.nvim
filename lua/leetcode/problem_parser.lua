local function display_formatted_text(raw_text)
  -- Step 1: Strip all HTML tags
  local function strip_html(html)
    return html:gsub("<[^>]+>", "")
  end
  local plain_text = strip_html(raw_text)

  -- Step 2: Split into lines and trim whitespace
  local lines = {}
  for line in plain_text:gmatch("[^\n]+") do
    table.insert(lines, line:match("^%s*(.-)%s*$")) -- Trim leading/trailing spaces
  end

  -- Step 3: Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Step 4: Define custom highlight groups (adjust colors as needed)
  vim.api.nvim_command([[
    hi def CustomHeader guifg=#98c379 gui=bold
    hi def CustomInput guifg=#e06c75
    hi def CustomOutput guifg=#98c379
    hi def CustomExplanation guifg=#56b6c2
    hi def CustomList guifg=#e5c07b
  ]])

  -- Step 5: Apply highlights based on line content
  local in_constraints = false
  for i, line in ipairs(lines) do
    local line_num = i - 1 -- Neovim uses 0-based indexing for lines
    if line:match("^Example %d+:") then
      vim.api.nvim_buf_add_highlight(buf, -1, "CustomHeader", line_num, 0, -1)
      in_constraints = false
    elseif line:match("^Input:") then
      vim.api.nvim_buf_add_highlight(buf, -1, "CustomInput", line_num, 0, -1)
      in_constraints = false
    elseif line:match("^Output:") then
      vim.api.nvim_buf_add_highlight(buf, -1, "CustomOutput", line_num, 0, -1)
      in_constraints = false
    elseif line:match("^Explanation:") then
      vim.api.nvim_buf_add_highlight(buf, -1, "CustomExplanation", line_num, 0, -1)
      in_constraints = false
    elseif line:match("^Constraints:") then
      vim.api.nvim_buf_add_highlight(buf, -1, "CustomHeader", line_num, 0, -1)
      in_constraints = true
    elseif in_constraints and line:match("^%s*-") then
      vim.api.nvim_buf_add_highlight(buf, -1, "CustomList", line_num, 0, -1)
    else
      in_constraints = false
    end
  end

  -- Step 6: Create a centered floating window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "single",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Step 7: Set buffer options and keymapping
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
end

-- Example usage with nested HTML tags
local raw_text = [[
<p>You are given two <strong>non-empty</strong> linked lists representing two non-negative integers. The digits are stored in <strong>reverse order</strong>, and each of their nodes contains a single digit. Add the two numbers and return the sum as a linked list.</p>

<p><strong class="example">Example 1:</strong></p>
<pre>
<strong>Input:</strong> l1 = [2,4,3], l2 = [5,6,4]
<strong>Output:</strong> [7,0,8]
<strong>Explanation:</strong> 342 + 465 = 807.
</pre>

<p><strong>Constraints:</strong></p>
<ul>
	<li>The number of nodes in each linked list is in the range <code>[1, 100]</code>.</li>
	<li><code>0 <= Node.val <= 9</code></li>
</ul>
]]

display_formatted_text(raw_text)

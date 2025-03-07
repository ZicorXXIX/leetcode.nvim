-- Define namespace and buffer/window variables at the top
local results_win, details_win = nil, nil
local results_buf, details_buf = nil, nil
local ns_id = vim.api.nvim_create_namespace("details_namespace")

local testcase = {}

-- Function to update Details window content based on the selected case
local function update_details_content(case_number)
  local case_content = {
    ["Case 1"] = { "This is the content for Case 1.", "It updates dynamically." },
    ["Case 2"] = { "Welcome to Case 2!", "Different content is shown here." },
    ["Case 3"] = { "Case 3 is selected.", "Final example of dynamic content." }
  }
  -- Clear and set new content below the buttons
  vim.api.nvim_buf_set_lines(details_buf, 6, -1, false, {})
  vim.api.nvim_buf_set_lines(details_buf, 6, -1, false, case_content[case_number])
end

-- Function to highlight the selected button
local function highlight_selected_button(case_number)
  local button_line = 3 -- Zero-based line number where buttons are
  -- Clear existing highlights on the button line
  vim.api.nvim_buf_clear_namespace(details_buf, ns_id, button_line, button_line + 1)
  -- Apply base highlight to the entire button line
  vim.api.nvim_buf_add_highlight(details_buf, ns_id, "WarningMsg", button_line, 0, -1)
  -- Get the line content to find button positions
  local line_content = vim.api.nvim_buf_get_lines(details_buf, button_line, button_line + 1, false)[1]
  local case_label = "[ Case " .. case_number:sub(6) .. " ]" -- e.g., "[ Case 1 ]"
  local start_col = string.find(line_content, case_label, 1, true) - 1 -- Convert to 0-based
  if start_col then
    local end_col = start_col + #case_label
    -- Apply highlight to the selected button
    vim.api.nvim_buf_add_highlight(details_buf, ns_id, "SelectedButton", button_line, start_col, end_col)
  end
end

-- Function to open Results and Details windows
testcase.render = function ()
  -- Close existing windows if open
  if results_win and vim.api.nvim_win_is_valid(results_win) then
    vim.api.nvim_win_close(results_win, true)
  end
  if details_win and vim.api.nvim_win_is_valid(details_win) then
    vim.api.nvim_win_close(details_win, true)
  end

  -- Create or reuse buffers
  results_buf = results_buf and vim.api.nvim_buf_is_valid(results_buf) and results_buf or vim.api.nvim_create_buf(false, true)
  details_buf = details_buf and vim.api.nvim_buf_is_valid(details_buf) and details_buf or vim.api.nvim_create_buf(false, true)

  -- Set Results buffer content
  local results_lines = {
    "lsp_outgoing_calls",
    "lsp_incoming_calls",
    "lsp_implementations",
    "git_files",
    "buffers",
    "autocommands"
  }
  vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, results_lines)

  -- Set initial Details buffer content with buttons
  local details_lines = {
    "-- Details Window --",
    "Press 1, 2, or 3 to select a case.",
    "",
    "[ Case 1 ]   [ Case 2 ]   [ Case 3 ]",
    "",
    "Select a case to update this content..."
  }
  vim.api.nvim_buf_set_lines(details_buf, 0, -1, false, details_lines)

  -- Calculate window positions
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")
  local win_width = 50
  local win_height = 15
  local gap = 2
  local row = math.floor((height - win_height) / 2)
  local col_left = math.floor((width - (win_width * 2 + gap)) / 2)
  local col_right = col_left + win_width + gap

  -- Open Results window (left)
  results_win = vim.api.nvim_open_win(results_buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col_left,
    style = "minimal",
    border = "rounded",
    title = " Results ",
    title_pos = "center",
  })

  -- Open Details window (right)
  details_win = vim.api.nvim_open_win(details_buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col_right,
    style = "minimal",
    border = "rounded",
    title = " Details ",
    title_pos = "center",
  })

  -- Apply base highlight to the buttons line
  vim.api.nvim_buf_add_highlight(details_buf, ns_id, "WarningMsg", 3, 0, -1)

  -- Define the SelectedButton highlight group
  vim.api.nvim_set_hl(0, "SelectedButton", { reverse = true }) -- Reverse colors to stand out

  -- Set key bindings for case selection
  vim.keymap.set("n", "1", function()
    update_details_content("Case 1")
    highlight_selected_button("Case 1")
  end, { buffer = details_buf, noremap = true, silent = true })

  vim.keymap.set("n", "2", function()
    update_details_content("Case 2")
    highlight_selected_button("Case 2")
  end, { buffer = details_buf, noremap = true, silent = true })

  vim.keymap.set("n", "3", function()
    update_details_content("Case 3")
    highlight_selected_button("Case 3")
  end, { buffer = details_buf, noremap = true, silent = true })
end

return testcase
-- Bind <leader>r to open the windows
-- vim.keymap.set("n", "<leader>r", open_results_windows, { noremap = true, silent = true })


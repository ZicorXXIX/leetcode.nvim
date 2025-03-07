local testcases = require("leetcode.ui.testcase")
local ui = {}

local ns_id = vim.api.nvim_create_namespace("details_namespace")

local function parse_test_cases(json_data)
    local cases = {}
    for i, expected in ipairs(json_data.expected_code_answer) do
        local actual = json_data.code_answer[i] or "" -- Handle possible missing entries
        cases["case " .. i] = { "| Output" .. actual, "| Expected" .. expected }
    end
    return cases
end

local function update_details_content(case_number, case_content)
    vim.api.nvim_buf_set_lines(details_buf, 6, -1, false, {})
    vim.api.nvim_buf_set_lines(details_buf, 6, -1, false, case_content[case_number] or { "No content found." })
end

local function highlight_selected_button(case_number)
    local button_line = 3 -- Zero-based line number where buttons are
    vim.api.nvim_buf_clear_namespace(details_buf, ns_id, button_line, button_line + 1)
    vim.api.nvim_buf_add_highlight(details_buf, ns_id, "WarningMsg", button_line, 0, -1)

    local line_content = vim.api.nvim_buf_get_lines(details_buf, button_line, button_line + 1, false)[1] or ""
    local case_label = "[ Case " .. case_number:sub(6) .. " ]" -- e.g., "[ Case 1 ]"
    local start_col = string.find(line_content, case_label, 1, true)

    if start_col then
        start_col = start_col - 1 -- Convert to 0-based index
        local end_col = start_col + #case_label
        vim.api.nvim_buf_add_highlight(details_buf, ns_id, "SelectedButton", button_line, start_col, end_col)
    end
end

ui.render_results = function (lines, result_type, input)
    local test_buf = vim.api.nvim_create_buf(false, true)
    details_buf = vim.api.nvim_create_buf(false, true) -- Use details_buf correctly

    local test_lines = { "Test Cases Placeholder" }
    local result_lines = {
        "-- Details Window --",
        "Press 1, 2, or 3 to select a case.",
        "",
        "[ Case 1 ]   [ Case 2 ]   [ Case 3 ]",
        "",
        "Select a case to update this content..."
    }

    vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, test_lines)
    vim.api.nvim_buf_set_lines(details_buf, 0, -1, false, result_lines)

    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")
    local gap = 2
    local win_width = 50
    local win_height = 20
    local row = math.floor((height - win_height) / 2)
    local col_left = math.floor((width - (win_width * 2 + gap)) / 2)
    local col_right = col_left + win_width + gap

    local test_win = vim.api.nvim_open_win(test_buf, true, {
        relative = "editor", width = win_width, height = win_height,
        row = row, col = col_left, style = "minimal", border = "rounded",
        title = " (H) Test Cases ", title_pos = "center",
    })

    details_win = vim.api.nvim_open_win(details_buf, true, {
        relative = "editor", width = win_width, height = win_height,
        row = row, col = col_right, style = "minimal", border = "rounded",
        title = " (L) Results ", title_pos = "center",
    })

    if result_type == "Wrong Answer" then
        local cases = {}
        -- for i, expected in ipairs(lines.expected_code_answer) do
        --     local actual = lines.code_answer[i] or ""
        --     cases["Case " .. i] = { " │ Output" .. actual, " │ Expected" .. expected }
        -- end

        for i, expected in ipairs(input) do
            local actual = lines.code_answer[i] or ""
            cases["Case " .. i] = { " │ Input" .. input[i]:gsub("\n", " "), " │ Output" .. actual, " │ Expected" .. lines.expected_code_answer[i] }
        end

        print(vim.inspect(cases))
        vim.api.nvim_buf_add_highlight(details_buf, ns_id, "WarningMsg", 3, 0, -1)
        vim.api.nvim_set_hl(0, "SelectedButton", { reverse = true })
        for case_name, case in pairs(cases) do
            local case_number = case_name:match("%d+")
            vim.keymap.set("n", case_number, function()
                update_details_content(case_name, cases)
                highlight_selected_button(case_name)
            end, { buffer = details_buf, noremap = true, silent = true })
        end
    end

    if result_type == "compile_error" then
        vim.api.nvim_win_set_option(details_win, "winhl", "Normal:ErrorMsg,FloatBorder:ErrorMsg,FloatTitle:ErrorMsg")
    end

    vim.api.nvim_win_set_option(details_win, "wrap", true)
    vim.api.nvim_buf_set_option(test_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(details_buf, "buftype", "nofile")
end


return ui

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

local ns_button_id = vim.api.nvim_create_namespace("button_namespace") -- For button highlights

local function highlight_selected_button(case_number)
    local button_line = 4 -- Line where case buttons exist
    vim.api.nvim_buf_clear_namespace(details_buf, ns_button_id, 0, -1) -- Clear only button highlights

    -- Get the line content
    local line_content = vim.api.nvim_buf_get_lines(details_buf, button_line, button_line + 1, false)[1] or ""
    local case_label = "[ Case " .. case_number:sub(6) .. " ]" -- e.g., "[ Case 1 ]"
    local start_col = string.find(line_content, case_label, 1, true)

    if start_col then
        start_col = start_col - 1 -- Convert to 0-based index
        local end_col = start_col + #case_label

        -- Set extmark for highlighting the selected button (use separate namespace)
        vim.api.nvim_buf_set_extmark(details_buf, ns_button_id, button_line, start_col, {
            end_col = end_col,
            hl_group = "GreenBackground",
        })
    end
end

-- local function highlight_selected_button(case_number)
--     local button_line = 4 -- Zero-based line number where buttons are
--     vim.api.nvim_buf_clear_namespace(details_buf, ns_id, 0, -1) -- Clear all highlights in namespace
--
--     -- Get the line content
--     local line_content = vim.api.nvim_buf_get_lines(details_buf, button_line, button_line + 1, false)[1] or ""
--     local case_label = "[ Case " .. case_number:sub(6) .. " ]" -- e.g., "[ Case 1 ]"
--     local start_col = string.find(line_content, case_label, 1, true)
--
--     if start_col then
--         start_col = start_col - 1 -- Convert to 0-based index
--         local end_col = start_col + #case_label
--
--         -- Set extmark for highlighting the selected button
--         vim.api.nvim_buf_set_extmark(details_buf, ns_id, button_line, start_col, {
--             end_col = end_col,
--             hl_group = "SelectedButton",
--             ephemeral = false, -- Ensures the highlight persists
--         })
--     end
-- end


-- local function highlight_selected_button(case_number)
--     local button_line = 4 -- Zero-based line number where buttons are
--     vim.api.nvim_buf_clear_namespace(details_buf, ns_id, button_line, button_line + 1)
--     vim.api.nvim_buf_add_highlight(details_buf, ns_id, "WarningMsg", button_line, 0, -1)
--
--     local line_content = vim.api.nvim_buf_get_lines(details_buf, button_line, button_line + 1, false)[1] or ""
--     local case_label = "[ Case " .. case_number:sub(6) .. " ]" -- e.g., "[ Case 1 ]"
--     local start_col = string.find(line_content, case_label, 1, true)
--
--     if start_col then
--         start_col = start_col - 1 -- Convert to 0-based index
--         local end_col = start_col + #case_label
--         vim.api.nvim_buf_add_highlight(details_buf, ns_id, "SelectedButton", button_line, start_col, end_col)
--     end
-- end
--
local function generate_case_buttons(num_cases)
    local case_buttons = {}
    for i = 1, num_cases do
        table.insert(case_buttons, "[ Case " .. i .. " ]")
    end
    return "   " .. table.concat(case_buttons, "   ")  -- Join buttons with spacing
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

    if result_type == "Wrong Answer" then
        result_lines = {
            "",
            "   Wrong Answer | Runtime: 0 ms",
            "",
            "",
             generate_case_buttons(#input),
            "",
            "Select a case to update this content..."
        }
    end

    if result_type == "Accepted" then
        result_lines = {
            "",
            "   Accepted | Runtime: 0 ms",
            "",
            "",
            "    [ Case 1 ]   [ Case 2 ]   [ Case 3 ]",
            "",
            "Select a case to update this content..."
        }
    end

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

    if result_type == "Wrong Answer" or "Accepted" then
        local cases = {}
        -- for i, expected in ipairs(lines.expected_code_answer) do
        --     local actual = lines.code_answer[i] or ""
        --     cases["Case " .. i] = { " │ Output" .. actual, " │ Expected" .. expected }
        -- end

        for i, expected in ipairs(input) do
            local actual = lines.code_answer[i] or ""
            cases["Case " .. i] = { "    │ Input:    " .. input[i]:gsub("\n", " "), "    │ Output:   " .. actual, "    │ Expected: " .. lines.expected_code_answer[i] }
        end

        local first_case_key = "Case 1"
        if cases[first_case_key] then
            update_details_content(first_case_key, cases)  -- Load first case content
            highlight_selected_button(first_case_key)       -- Highlight first case button
        end

        print(vim.inspect(cases))
        vim.api.nvim_buf_add_highlight(details_buf, ns_id, "WarningMsg", 3, 0, -1)
        vim.api.nvim_set_hl(0, "SelectedButton", { reverse = true })

        vim.api.nvim_set_hl(0, "ErrorText", { fg = "red", bold = true })
        vim.api.nvim_set_hl(0, "InfoText", { fg = "grey" })


        local line_number = 1  -- Assuming it's the second line in result_lines

        -- Find the start and end positions of each section
        local line_content = result_lines[line_number + 1]  -- Get actual text from the buffer
        local wrong_answer_start, wrong_answer_end = string.find(line_content, "Wrong Answer")
        local accepted_answer_start, accepted_answer_end= string.find(line_content, "Accepted")
        local runtime_start, runtime_end = string.find(line_content, "| Runtime")


        --Highlight Window
        -- vim.api.nvim_win_set_option(details_win, "winhl", "FloatBorder:GreenBorder,FloatTitle:ErrorMsg")
        vim.cmd([[
        highlight Green guifg=#2bbb5d
        highlight GreenBackground guibg=#2bbb5d
        highlight GreenTitle guifg=#2bbb5d guibg=none
        ]])

        if result_type == "Accepted"  then
            vim.api.nvim_win_set_option(details_win, "winhl", "FloatBorder:Green,FloatTitle:GreenTitle")
        else
            vim.api.nvim_win_set_option(details_win, "winhl","FloatBorder:ErrorMsg,FloatTitle:ErrorMsg")
        end


        if accepted_answer_start and accepted_answer_end then
            vim.api.nvim_buf_set_extmark(details_buf, ns_id, line_number, accepted_answer_start - 1, {
                end_col = accepted_answer_end,
                hl_group = "Green",
            })
        end

        if wrong_answer_start and wrong_answer_end then
            vim.api.nvim_buf_set_extmark(details_buf, ns_id, line_number, wrong_answer_start - 1, {
                end_col = wrong_answer_end,
                hl_group = "ErrorText",
            })
        end

        if runtime_start and runtime_end then
            vim.api.nvim_buf_set_extmark(details_buf, ns_id, line_number, runtime_start - 1, {
                end_col = runtime_end,
                hl_group = "InfoText",
            })
        end

        -- if wrong_answer_start then
        --     vim.api.nvim_buf_add_highlight(details_buf, 0, "ErrorText", 0, wrong_answer_start - 1, runtime_start - 2) -- "Wrong Answer" in red
        -- end
        --
        -- if runtime_start then
        --     vim.api.nvim_buf_add_highlight(details_buf, 0, "InfoText", 0, runtime_start - 1, -1) -- "| Runtime 1 ms" in grey
        -- end

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

local config = require('leetcode.config')

-- Ensure required modules are available
local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
  print("Telescope.nvim is not installed. Please install it first.")
  return
end

telescope.setup()

local pickers_ok, pickers = pcall(require, 'telescope.pickers')
if not pickers_ok then
  print("Failed to load telescope.pickers module.")
  return
end

local finders_ok, finders = pcall(require, 'telescope.finders')
if not finders_ok then
  print("Failed to load telescope.finders module.")
  return
end

local sorters_ok, sorters = pcall(require, 'telescope.sorters')
if not sorters_ok then
  print("Failed to load telescope.sorters module.")
  return
end

local actions_ok, actions = pcall(require, 'telescope.actions')
if not actions_ok then
  print("Failed to load telescope.actions module.")
  return
end

-- Ensure plenary.curl is loaded correctly
local curl_ok, curl = pcall(require, 'plenary.curl')
if not curl_ok then
  print("Plenary.nvim curl module is unavailable. Please ensure plenary.nvim is installed correctly.")
  return
end

-- Cache file path
local cache_file = vim.fn.stdpath('cache') .. '/leetcode_problems.json'

-- Function to fetch problems list from LeetCode API
local function fetch_leetcode_problems()
  local url = "https://leetcode.com/api/problems/all/"

  local headers = {
    ["Cookie"] = string.format("LEETCODE_SESSION=%s; csrftoken=%s", config.leetcode_session, config.csrf_token),
    ["Content-Type"] = "application/json",
    ["x-csrftoken"] = config.csrf_token,
  }

  local response = curl.get(url, {
    headers = headers,
    timeout = 10000, -- 10 seconds timeout
  })

  if response.status == 200 then
    local data = vim.fn.json_decode(response.body)
    if data and data.stat_status_pairs then
      local problems = {}
      for _, pair in ipairs(data.stat_status_pairs) do
        local title = pair.stat.question__title
        local difficulty = pair.difficulty.level
        local frontend_id = pair.stat.frontend_question_id
        table.insert(problems, { 
          title = title, 
          difficulty = difficulty, 
          slug = pair.stat.question__title_slug,
          frontend_id = frontend_id
        })
      end
      vim.fn.writefile({vim.fn.json_encode(problems)}, cache_file)
      return problems
    else
      print("Invalid response format from LeetCode API")
      return {}
    end
  else
    print("Failed to fetch problems, status code: " .. response.status .. " - " .. (response.body or "No body"))
    return {}
  end
end

-- Fetch names (from LeetCode API or cache)
local function fetch_names()
  if vim.fn.filereadable(cache_file) == 1 then
    local cached_data = vim.fn.json_decode(vim.fn.readfile(cache_file))
    if cached_data then
      return cached_data
    end
  end
  return fetch_leetcode_problems()
end

-- Function to load the selected problem using the functions from init.lua
local function load_problem(slug)
  local leetcode = require('leetcode')
  print(slug)
  leetcode.fetch_question(slug)
end

-- Define highlight groups for difficulties
local function setup_highlights()
  vim.cmd([[
    highlight! LeetCodeEasy guifg=#98c379 gui=bold
    highlight! LeetCodeMedium guifg=#e5c07b gui=bold
    highlight! LeetCodeHard guifg=#e06c75 gui=bold
  ]])
end

-- Telescope picker for names
local function names_picker()
  setup_highlights()
  local problems = fetch_names()
  if not problems or #problems == 0 then
    print("No problems available to display")
    return
  end

  pickers.new({}, {
    prompt_title = "Search LeetCode Problems",
    finder = finders.new_table({
      results = problems,
      entry_maker = function(entry)
        local difficulty = ""
        local hl_group = ""
        if entry.difficulty == 1 then
          difficulty = "Easy"
          hl_group = "LeetCodeEasy"
        elseif entry.difficulty == 2 then
          difficulty = "Medium"
          hl_group = "LeetCodeMedium"
        elseif entry.difficulty == 3 then
          difficulty = "Hard"
          hl_group = "LeetCodeHard"
        end

        local display = string.format("%s. %s [%s]", 
          entry.frontend_id,
          entry.title,
          difficulty
        )

        return {
          value = entry.slug,
          display = display,
          ordinal = entry.title,
          difficulty = difficulty,
          hl_group = hl_group,
        }
      end,
    }),
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      map('i', '<CR>', function()
        local selected = require('telescope.actions.state').get_selected_entry()
        actions.close(prompt_bufnr)
        load_problem(selected.value)
      end)
      return true
    end,
    previewer = false,
    default_selection_index = 1,
    layout_config = {
      width = 0.8,
      height = 0.8,
    },
    results_title = "LeetCode Problems",
    selection_strategy = "reset",
    sorting_strategy = "ascending",
    border = true,
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    winblend = 0,
    entry_prefix = "  ",
    initial_mode = "insert",
    scroll_strategy = "cycle",
    selection_caret = "  ",
    get_status_text = function(self)
      return ""
    end,
    on_complete = {
      function()
        vim.cmd([[
          augroup LeetCodePicker
            autocmd!
            autocmd BufEnter <buffer> highlight! link TelescopeResultsNormal NormalFloat
            autocmd BufEnter <buffer> highlight! link TelescopeBorder NormalFloat
          augroup END
        ]])
      end
    }
  }):find()
end

-- Expose the function as a command
vim.api.nvim_create_user_command('LS', names_picker, {})

-- Optional: Print instructions if sourced manually
print("Run :LS to open the LeetCode problems picker. Update cookies in the script first!")

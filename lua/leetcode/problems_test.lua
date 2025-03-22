  -- Ensure required modules are available
  --
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
        table.insert(problems, title)
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

-- Telescope picker for names
local function names_picker()
  local names = fetch_names()
  if not names or #names == 0 then
    print("No names available to display")
    return
  end

  pickers.new({}, {
    prompt_title = "Search LeetCode Problems",
    finder = finders.new_table({
      results = names,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry, -- For fuzzy filtering
        }
      end,
    }),
    sorter = sorters.get_generic_fuzzy_sorter(),
  }):find()
end

-- Expose the function as a command
vim.api.nvim_create_user_command('LS', names_picker, {})

-- Optional: Print instructions if sourced manually
print("Run :LS to open the LeetCode problems picker. Update cookies in the script first!")

-- Ensure Telescope is available
local status_ok, telescope = pcall(require, 'telescope')
if not status_ok then
  print("Telescope.nvim is not installed. Please install it first.")
  return
end

-- Ensure Telescope is initialized
telescope.setup()

-- Load required Telescope modules directly
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

-- Load plenary for cache handling
local plenary_ok, plenary = pcall(require, 'plenary')
if not plenary_ok then
  print("Plenary.nvim is not installed. Please install it first.")
  return
end

local http = plenary.http

-- Cache file path
local cache_file = vim.fn.stdpath('cache') .. '/names.json'

-- Mock API response generator (for testing)
local function generate_mock_data()
  local names = {}
  local first_names = {"John", "Jane", "Alex", "Sara", "Mike", "Emily", "Tom", "Lucy"}
  local last_names = {"Smith", "Doe", "Johnson", "Brown", "Davis", "Wilson", "Taylor", "Clark"}
  math.randomseed(os.time()) -- Seed for randomness
  for i = 1, 20 do
    local full_name = first_names[math.random(#first_names)] .. " " .. last_names[math.random(#last_names)]
    table.insert(names, { name = full_name })
  end
  return names
end

-- Fetch names (mocked or from cache)
local function fetch_names()
  -- Check if cache exists
  if vim.fn.filereadable(cache_file) == 1 then
    local cached_data = vim.fn.json_decode(vim.fn.readfile(cache_file))
    if cached_data then
      return cached_data
    end
  end

  -- Generate mock data
  local mock_data = generate_mock_data()
  vim.fn.writefile({vim.fn.json_encode(mock_data)}, cache_file)
  return mock_data
end

-- Telescope picker for names
local function names_picker()
  local names = fetch_names()
  if not names or #names == 0 then
    print("No names available to display")
    return
  end

  -- Extract just the names for display
  local display_names = {}
  for _, item in ipairs(names) do
    table.insert(display_names, item.name)
  end

  pickers.new({}, {
    prompt_title = "Search Names",
    finder = finders.new_table({
      results = display_names,
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
vim.api.nvim_create_user_command('SearchNames', names_picker, {})

-- Optional: Print instructions if sourced manually
print("Run :SearchNames to open the names picker. Type to filter.")

local leetcode = {}

leetcode.setup = function (opts)
    print("Hello from Options:", opts)
end

local curl = require("plenary.curl")
local config = require("leetcode.config")
local utils = require("leetcode.utils")

-- print(config)


local headers = {
  ["Cookie"] = string.format("LEETCODE_SESSION=%s;csrftoken=%s", config.leetcode_session, config.csrf_token),
  ["Content-Type"] = "application/json",
  ["Accept"] = "application/json",
  ["x-csrftoken"] = config.csrf_token,
}

local function fetch_question(slug)
    local variables = {
    titleSlug = slug,
  }

  local query = [[
  query questionData($titleSlug: String!) {
      question(titleSlug: $titleSlug) {
          questionId
          questionFrontendId
          ]] .. [[
          title
          content
          ]] .. [[
          codeSnippets {
              lang
              langSlug
              code
          }
      }
  }
  ]]

  local response = curl.post("https://leetcode.com/graphql/", {
      headers = headers,
      body = vim.fn.json_encode({ query = query, variables = variables })
  })

  local decoded = vim.json.decode(response.body)
  local content = decoded.data.question.content

  local entities = {
    { "amp", "&" },
    { "apos", "'" },
    { "#x27", "'" },
    { "#x2F", "/" },
    { "#39", "'" },
    { "#47", "/" },
    { "lt", "<" },
    { "gt", ">" },
    { "nbsp", " " },
    { "quot", '"' },
  }

  local img_urls = {}
  content = content:gsub("<img.-src=[\"'](.-)[\"'].->", function(url)
    table.insert(img_urls, url)
    return "##IMAGE##"
  end)
  content = string.gsub(content, "<[^>]+>", "")

  for _, url in ipairs(img_urls) do
    content = string.gsub(content, "##IMAGE##", url, 1)
  end

  for _, entity in ipairs(entities) do
    content = string.gsub(content, "&" .. entity[1] .. ";", entity[2])
  end

  print(content)

  utils.create_file(content)
end

fetch_question("add-two-numbers")
return leetcode

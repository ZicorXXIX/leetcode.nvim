local leetcode = {}

leetcode.setup = function (opts)
    print("Hello from Options:", opts)
end

local curl = require("plenary.curl")
local config = require("leetcode.config")
local utils = require("leetcode.utils")
local ui = require("leetcode.ui.results")

-- print(config)


local headers = {
  ["Cookie"] = string.format("LEETCODE_SESSION=%s; csrftoken=%s", config.leetcode_session, config.csrf_token),
  ["Content-Type"] = "application/json",
  ["Accept"] = "application/json",
  ["x-csrftoken"] = config.csrf_token,
}

local state = {}

leetcode.fetch_question = function(slug)
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
          exampleTestcaseList
      }
  }
  ]]

  local response = curl.post("https://leetcode.com/graphql/", {
      headers = headers,
      body = vim.fn.json_encode({ query = query, variables = variables })
  })

  local decoded = vim.json.decode(response.body)
  local content = decoded.data.question.content
  local codeSnippets =  decoded.data.question.codeSnippets
  state.test_cases = decoded.data.question.exampleTestcaseList
  state.questionId = decoded.data.question.questionId
  print(vim.inspect(state.test_cases))

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
  -- content = string.gsub(content, "<[^>]+>", "")

  for _, url in ipairs(img_urls) do
    content = string.gsub(content, "##IMAGE##", url, 1)
  end

  for _, entity in ipairs(entities) do
    content = string.gsub(content, "&" .. entity[1] .. ";", entity[2])
  end

  print(vim.inspect(codeSnippets[1]))

  utils.create_file(content, codeSnippets)
end

leetcode.interpret = function ()
    local endpoint = "https://leetcode.com/problems/two-sum/interpret_solution/"
    -- data_input: "[2,7,11,15]\n9\n[3,2,4]\n6\n[3,3]\n6"
    -- lang : "cpp"
    -- question_id: "1"
    -- typed_code :
    local buffer = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
    local typed_code = table.concat(lines, "\n")
    local test_cases = ""

    print("Original Test Cases:", vim.inspect(state.test_cases))

    for i, str in ipairs(state.test_cases) do
        if test_cases == "" then
            test_cases = str
        end
        test_cases = test_cases .. "\n" .. str
    end


    local query = {
        ["lang"] = "cpp",
        question_id = state.questionId,
        -- typed_code = typed_code,
        typed_code = [[class Solution {
public:
    vector<int> twoSum(vector<int>& nums, int target) {
        unordered_map<int, int> d;
        for (int i = 0;; ++i) {
            int x = nums[i];
            int y = target - x;
            if (d.contains(y)) {
                return {d[y], i};
            }
            d[x] = 8;
        }
    }
};]],
        data_input = test_cases
    }
    print(vim.inspect(query))
    local json = vim.fn.json_encode(query)
    print(json)
    headers = vim.tbl_extend("force", {
        ["Referer"] = "https://leetcode.com/problems/two-sum/"
    }, headers)
    print(vim.inspect(headers))
    local response = curl.post( endpoint , {
        headers = headers,
        body = json
    })
    print("response:", vim.inspect(response))
    local json = vim.fn.json_decode(response.body)
    print(json.interpret_id)
    leetcode.check(json.interpret_id)
    -- while true do
    --     if(state.check_status ~= "PENDING") then
    --         print(vim.inspect(state.check_status))
    --         break
    --     end
    -- end
end


leetcode.check = function (id)
    local endpoint = string.format("https://leetcode.com/submissions/detail/%s/check/", id)
    headers = vim.tbl_extend("force", {
        ["Referer"] = "https://leetcode.com/problems/two-sum/"
    }, headers)

    if id then
        print("after 1 sec")
        local response = curl.get(endpoint, { headers = headers } )
        local body = vim.fn.json_decode(response.body)
        print(vim.inspect(body))
        if body.state == "PENDING" then
            print("inside Pending")
            state.check_status = body.state
            vim.defer_fn(function ()
                leetcode.check(id)
            end, 1000)  -- delay 1 second
        elseif body.state == "SUCCESS" then
            local json = vim.fn.json_decode(response.body)
            print(vim.inspect(json.status_code))
            print(vim.inspect(json.full_compile_error))

            local lines_to_render
            if json.status_code == 20 then
                local fail_result = { json.status_msg }
                -- fail_result = vim.tbl_extend("force", vim.split(json.full_compile_error, "\n", {plain = true}), fail_result)
                fail_result = vim.list_extend(fail_result, vim.split(json.full_compile_error, "\n", {plain = true}))
                lines_to_render = fail_result
            else if json.status_code == 10 then
                lines_to_render = json
                ui.render_results(lines_to_render, "Wrong Answer", state.test_cases)
            end
                lines_to_render = {"test"}  -- Or other success content
            end
            -- ui.render_results(lines_to_render, "compile_error")
            state.check_status = body.state
        end
    end
end

 leetcode.fetch_question("two-sum")
 leetcode.interpret()
 -- ui.render_results({"test"})
return leetcode

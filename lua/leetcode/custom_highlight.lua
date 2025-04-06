-- Function to display HTML content in a new Neovim window with proper syntax highlighting
function DisplayHTML(html_content)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Process the HTML content to remove tags and prepare for display
  local processed_content = ProcessHTMLContent(html_content)
  
  -- Set the buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(processed_content.text, '\n'))
  
  -- Create a new window that splits the current one
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    row = math.floor(vim.o.lines * 0.1),
    col = math.floor(vim.o.columns * 0.1),
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Set the buffer filetype for basic HTML highlighting
  vim.api.nvim_buf_set_option(buf, 'filetype', 'html')
  
  -- Define our custom highlighting
  DefineCustomHighlights()
  
  -- Apply custom highlights based on the original tags
  ApplyCustomHighlights(buf, processed_content.highlights)
  
  -- Print debug info
  PrintHighlightsDebug(processed_content.highlights)
  
  return buf, win
end

-- Function to process HTML content, removing tags and tracking positions for highlighting
function ProcessHTMLContent(html_content)
  local text = ""
  local highlights = {}
  local line_num = 0
  local col_num = 0
  local tag_stack = {}
  
  local i = 1
  while i <= #html_content do
    -- Check for opening tag
    if html_content:sub(i, i) == '<' then
      local tag_end = html_content:find('>', i)
      if tag_end then
        local tag = html_content:sub(i, tag_end)
        
        -- Extract tag name and attributes
        local tag_name = tag:match('</?([%w%-]+)')
        local tag_class = tag:match('class="([^"]*)"')
        
        if tag_name then
          local highlight_group = GetHighlightGroup(tag_name, tag_class)
          
          if tag:sub(2, 2) ~= '/' then  -- Opening tag
            -- Push to stack
            table.insert(tag_stack, {
              tag = tag_name,
              start = {line = line_num, col = col_num},
              highlight_group = highlight_group
            })
          else  -- Closing tag
            -- Pop from stack
            for j = #tag_stack, 1, -1 do
              if tag_stack[j].tag == tag_name then
                local highlight = tag_stack[j]
                highlight.end_pos = {line = line_num, col = col_num - 1}
                
                -- Only add if we have content (start != end)
                if highlight.start.line ~= highlight.end_pos.line or 
                   highlight.start.col ~= highlight.end_pos.col then
                  table.insert(highlights, highlight)
                end
                
                table.remove(tag_stack, j)
                break
              end
            end
          end
        
          i = tag_end + 1
        else
          -- Not a valid tag, treat as text
          text = text .. html_content:sub(i, i)
          col_num = col_num + 1
          i = i + 1
        end
      else
        -- If no closing '>' is found, treat '<' as a regular character
        text = text .. html_content:sub(i, i)
        col_num = col_num + 1
        i = i + 1
      end
    elseif html_content:sub(i, i) == '\n' then
      text = text .. '\n'
      line_num = line_num + 1
      col_num = 0
      i = i + 1
    else
      text = text .. html_content:sub(i, i)
      col_num = col_num + 1
      i = i + 1
    end
  end
  
  -- Debug output
  print("Processed text, found " .. #highlights .. " highlight regions")
  
  return {text = text, highlights = highlights}
end

-- Function to determine highlight group based on tag name and class
function GetHighlightGroup(tag_name, tag_class)
  local highlight_groups = {
    p = "htmlParagraph",
    strong = "htmlBold",
    em = "htmlItalic",
    code = "htmlCode",
    pre = "htmlPreProc",
    ul = "htmlList",
    li = "htmlListItem",
    a = "htmlLink",
    h1 = "htmlH1",
    h2 = "htmlH2",
    h3 = "htmlH3",
    img = "htmlSpecial"
  }
  
  -- Enhanced class-based highlighting for LeetCode examples
  if tag_class then
    if tag_class:match("example") then
      return "htmlExampleTitle"
    elseif tag_class:match("input") then
      return "htmlExampleInput"
    elseif tag_class:match("output") then
      return "htmlExampleOutput"
    elseif tag_class:match("explanation") then
      return "htmlExampleExplanation"
    end
  end
  
  return highlight_groups[tag_name] or "Normal"
end

-- Function to define custom highlight groups
function DefineCustomHighlights()
  -- Set up highlight groups with clear, distinctive colors
  vim.cmd([[
    highlight clear htmlParagraph
    highlight clear htmlBold
    highlight clear htmlItalic
    highlight clear htmlCode
    highlight clear htmlPreProc
    highlight clear htmlSpecialChar
    highlight clear htmlH1
    highlight clear htmlH2
    highlight clear htmlH3
    highlight clear htmlLink
    highlight clear htmlSpecial
    highlight clear htmlList
    highlight clear htmlListItem
    
    " Base colors
    highlight htmlParagraph guifg=#abb2bf gui=none
    highlight htmlBold guifg=#e5c07b gui=bold
    highlight htmlItalic guifg=#56b6c2 gui=italic
    highlight htmlCode guifg=#98c379 gui=none
    highlight htmlPreProc guibg=#282c34 guifg=#abb2bf gui=none
    highlight htmlSpecialChar guifg=#e06c75 gui=bold
    highlight htmlH1 guifg=#61afef gui=bold
    highlight htmlH2 guifg=#61afef gui=bold
    highlight htmlH3 guifg=#61afef gui=bold
    highlight htmlLink guifg=#c678dd gui=underline
    highlight htmlSpecial guifg=#56b6c2 gui=italic
    highlight htmlList guifg=#abb2bf gui=none
    highlight htmlListItem guifg=#abb2bf gui=none

    " Example-specific highlights
    highlight htmlExampleTitle guifg=#e5c07b gui=bold
    highlight htmlExampleInput guifg=#98c379 gui=none
    highlight htmlExampleOutput guifg=#e06c75 gui=none
    highlight htmlExampleExplanation guifg=#56b6c2 gui=italic
  ]])
end

-- Debug function to print highlight information
function PrintHighlightsDebug(highlights)
  print("Highlight regions found: " .. #highlights)
  for i, highlight in ipairs(highlights) do
    print(string.format(
      "Region %d: %s from (%d,%d) to (%d,%d) with group %s",
      i,
      highlight.tag or "unknown",
      highlight.start.line, highlight.start.col,
      highlight.end_pos.line, highlight.end_pos.col,
      highlight.highlight_group or "Normal"
    ))
  end
end

-- Function to apply custom highlights to the buffer
function ApplyCustomHighlights(buf, highlights)
  -- Create namespace for highlights
  local ns_id = vim.api.nvim_create_namespace("html_display")
  
  -- Apply highlights
  for _, highlight in ipairs(highlights) do
    if highlight.start and highlight.end_pos then
      -- Debugging
      print(string.format(
        "Applying %s highlight from line %d col %d to line %d col %d", 
        highlight.highlight_group, 
        highlight.start.line, highlight.start.col,
        highlight.end_pos.line, highlight.end_pos.col
      ))
      
      -- If highlighting is on a single line
      if highlight.start.line == highlight.end_pos.line then
        vim.api.nvim_buf_add_highlight(
          buf,
          ns_id,
          highlight.highlight_group,
          highlight.start.line,
          highlight.start.col,
          highlight.end_pos.col + 1  -- Add 1 to include the last character
        )
      else
        -- First line (partial)
        vim.api.nvim_buf_add_highlight(
          buf,
          ns_id,
          highlight.highlight_group,
          highlight.start.line,
          highlight.start.col,
          -1  -- To the end of the line
        )
        
        -- Middle lines (full)
        for line = highlight.start.line + 1, highlight.end_pos.line - 1 do
          vim.api.nvim_buf_add_highlight(
            buf,
            ns_id,
            highlight.highlight_group,
            line,
            0,
            -1
          )
        end
        
        -- Last line (partial)
        vim.api.nvim_buf_add_highlight(
          buf,
          ns_id,
          highlight.highlight_group,
          highlight.end_pos.line,
          0,
          highlight.end_pos.col + 1  -- Add 1 to include the last character
        )
      end
    end
  end
end

-- Example usage with proper syntax
vim.api.nvim_create_user_command("DisplayHTML", function()
  local html_content = vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  DisplayHTML(html_content)
end, {})

-- Create command for visual selection with proper syntax
vim.api.nvim_create_user_command("DisplaySelectedHTML", function()
  -- Get the start and end positions of the visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  -- Extract line and column numbers (fixing array indices)
  local start_line = start_pos[2] - 1
  local start_col = start_pos[3]
  local end_line = end_pos[2] - 1
  local end_col = end_pos[3]
  
  -- Get the selected lines
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
  
  -- Adjust first and last line for partial selection
  if #lines > 0 then
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
  end
  
  local selected_text = table.concat(lines, "\n")
  DisplayHTML(selected_text)
end, {range = true})

-- Example execution function
function ExampleExecution()
  local sample_html = [[
<p>You are given two <strong>non-empty</strong> linked lists representing two non-negative integers. The digits are stored in <strong>reverse order</strong>, and each of their nodes contains a single digit. Add the two numbers and return the sum&nbsp;as a linked list.</p>

<p>You may assume the two numbers do not contain any leading zero, except the number 0 itself.</p>

<p>&nbsp;</p>
<p><strong class="example">Example 1:</strong></p>
<img alt="" src="https://assets.leetcode.com/uploads/2020/10/02/addtwonumber1.jpg" style="width: 483px; height: 342px;" />
<pre>
<strong>Input:</strong> l1 = [2,4,3], l2 = [5,6,4]
<strong>Output:</strong> [7,0,8]
<strong>Explanation:</strong> 342 + 465 = 807.
</pre>
  ]]

  DisplayHTML(sample_html)
  print("HTML content displayed in a new window with syntax highlighting")
end

-- Create command to run the example
vim.api.nvim_create_user_command("HTMLExample", function()
  ExampleExecution()
end, {})

-- Optional: Set up key mappings
vim.api.nvim_set_keymap('n', '<Leader>dh', ':DisplayHTML<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('v', '<Leader>dh', ':DisplaySelectedHTML<CR>', {noremap = true, silent = true})

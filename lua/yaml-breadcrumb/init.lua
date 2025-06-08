local config = require("yaml-breadcrumb.config")

local M = {}

-- Default configuration
M.config = config.defaults()

-- Setup function
function M.setup(opts)
  opts = opts or {}

  config.validate(opts)

  M.config = vim.tbl_deep_extend("force", M.config, opts)
  
  if not M.config.enabled then
    return
  end
  
  M.init()
end

-- Plugin initialization
function M.init()
  -- Create user commands
  vim.api.nvim_create_user_command("YamlBreadcrumb", function()
    M.show_breadcrumb()
  end, { desc = "Show YAML breadcrumb for current line" })
  
  vim.api.nvim_create_user_command("YamlBreadcrumbToggle", function()
    M.toggle()
  end, { desc = "Toggle YAML breadcrumb display" })
  
  vim.api.nvim_create_user_command("YamlBreadcrumbHealth", function()
    vim.cmd("checkhealth yaml-breadcrumb")
  end, { desc = "Run YAML breadcrumb health check" })
  
  -- Set up keymaps
  M.setup_keymaps()
  
  -- Set up autocommands
  if M.config.show_on_cursor_move then
    M.setup_autocommands()
  end
end

-- Set up keymaps
function M.setup_keymaps()
  local opts = { noremap = true, silent = true }
  
  vim.keymap.set("n", "<leader>yb", function()
    M.show_breadcrumb()
  end, vim.tbl_extend("force", opts, { desc = "Show YAML breadcrumb" }))
  
  vim.keymap.set("n", "<leader>yt", function()
    M.toggle()
  end, vim.tbl_extend("force", opts, { desc = "Toggle YAML breadcrumb" }))
end

-- Set up autocommands
function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup("YamlBreadcrumb", { clear = true })
  
  vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
    group = group,
    pattern = "*.yaml,*.yml",
    callback = function()
      if M.config.enabled then
        M.update_breadcrumb()
      end
    end,
  })
  
  -- Clear virtual text when leaving yaml files
  vim.api.nvim_create_autocmd({"BufLeave"}, {
    group = group,
    pattern = "*.yaml,*.yml",
    callback = function()
      M.clear_virtual_text()
    end,
  })
end

-- Main function to show breadcrumb
function M.show_breadcrumb()
  if not M.is_yaml_file() then
    vim.notify("Not a YAML file", vim.log.levels.WARN)
    return
  end
  
  local breadcrumb = M.get_yaml_breadcrumb()
  if breadcrumb then
    local message = M.format_breadcrumb(breadcrumb)
    vim.notify(message, vim.log.levels.INFO)
    
    -- Debug: show what we detected
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
    local key, is_array = M.extract_key(line_content)
    vim.notify("Debug - Line: '" .. line_content .. "', Key: " .. (key or "nil") .. ", IsArray: " .. tostring(is_array), vim.log.levels.INFO)
    
    if M.config.virtual_text then
      M.show_virtual_text(message)
    end
  else
    vim.notify("No YAML path found", vim.log.levels.INFO)
  end
end

-- Update breadcrumb (for auto-update)
function M.update_breadcrumb()
  if not M.config.enabled or not M.is_yaml_file() then
    return
  end
  
  local breadcrumb = M.get_yaml_breadcrumb()
  if breadcrumb and M.config.virtual_text then
    local message = M.format_breadcrumb(breadcrumb)
    M.show_virtual_text(message)
  else
    M.clear_virtual_text()
  end
end

-- Check if current file is YAML
function M.is_yaml_file()
  local filetype = vim.bo.filetype
  local filename = vim.fn.expand("%:t")
  return filetype == "yaml" or filename:match("%.ya?ml$")
end

-- Get YAML breadcrumb path
function M.get_yaml_breadcrumb()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, current_line, false)
  
  local breadcrumb = {}
  local array_counters = {}
  
  for i, line in ipairs(lines) do
    -- Skip empty lines and comments
    if line:match("^%s*$") or line:match("^%s*#") then
      goto continue
    end
    
    local indent_level = M.get_indent_level(line)
    local key, is_array_item, is_array_with_key = M.extract_key(line)
    
    if key or is_array_item then
      -- Clear counters for levels we're backing out of
      for level, _ in pairs(array_counters) do
        if level > indent_level then
          array_counters[level] = nil
        end
      end
      
      -- Remove breadcrumb items that are at higher indentation levels
      local new_breadcrumb = {}
      for _, item in ipairs(breadcrumb) do
        if item.indent < indent_level then
          table.insert(new_breadcrumb, item)
        elseif item.indent == indent_level then
          -- Only keep items at same level if they are array items and this is not an array item
          if item.is_array_item and not is_array_item then
            table.insert(new_breadcrumb, item)
          end
          -- If this is an array item, don't keep any items at the same level
          break
        end
      end
      breadcrumb = new_breadcrumb
      
      if is_array_item then
        -- Handle array items
        if not array_counters[indent_level] then
          array_counters[indent_level] = 0
        else
          array_counters[indent_level] = array_counters[indent_level] + 1
        end
        
        local array_key = "[" .. array_counters[indent_level] .. "]"
        
        -- Add array index to breadcrumb
        table.insert(breadcrumb, {
          key = array_key,
          line = i,
          indent = indent_level,
          is_array_item = true
        })
        
        -- If this array item has a key (like "- name: value"), add the key too
        if is_array_with_key and key then
          table.insert(breadcrumb, {
            key = key,
            line = i,
            indent = indent_level + 2, -- Make it clearly deeper than the array item
            is_array_item = false
          })
        end
      elseif key then
        -- Handle regular keys
        table.insert(breadcrumb, {
          key = key,
          line = i,
          indent = indent_level,
          is_array_item = false
        })
      end
    end
    
    ::continue::
  end
  
  return #breadcrumb > 0 and breadcrumb or nil
end

-- Get indentation level of a line
function M.get_indent_level(line)
  local indent = line:match("^(%s*)")
  return #indent
end

-- Extract key from YAML line
function M.extract_key(line)
  -- Check for array item with key (- key: value)
  local array_key = line:match("^%s*%-%s*([^:#%s][^:#]*):") 
  if array_key then
    return array_key:gsub("%s+$", ""), true, true -- key, is_array_item, is_array_with_key
  end
  
  -- Check for simple array item (- value or just -)
  if line:match("^%s*%-") then
    return nil, true, false -- no key, is_array_item, not array_with_key
  end
  
  -- Check for regular key: value or key:
  local key = line:match("^%s*([^:#%s][^:#]*):") 
  if key then
    return key:gsub("%s+$", ""), false, false -- key, not_array_item, not_array_with_key
  end
  
  return nil, false, false
end

-- Format breadcrumb for display
function M.format_breadcrumb(breadcrumb)
  local parts = {}
  
  for _, item in ipairs(breadcrumb) do
    local part = item.key
    if M.config.show_line_numbers then
      part = part .. " (L" .. item.line .. ")"
    end
    table.insert(parts, part)
  end
  
  return table.concat(parts, M.config.separator)
end

-- Show virtual text
function M.show_virtual_text(text)
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  
  -- Clear existing virtual text
  M.clear_virtual_text()
  
  -- Create namespace if it doesn't exist
  if not M.namespace then
    M.namespace = vim.api.nvim_create_namespace("yaml_breadcrumb")
  end
  
  -- Add virtual text
  vim.api.nvim_buf_set_extmark(bufnr, M.namespace, line, 0, {
    virt_text = {{ "🍞 " .. text, M.config.highlight_group }},
    virt_text_pos = "eol",
  })
end

-- Clear virtual text
function M.clear_virtual_text()
  if M.namespace then
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
  end
end

-- Toggle plugin
function M.toggle()
  M.config.enabled = not M.config.enabled
  
  if M.config.enabled then
    M.setup_autocommands()
    vim.notify("YAML breadcrumb enabled", vim.log.levels.INFO)
  else
    M.clear_virtual_text()
    vim.notify("YAML breadcrumb disabled", vim.log.levels.INFO)
  end
end

-- Get current breadcrumb (for statusline integration)
function M.get_current_breadcrumb()
  if not M.config.enabled or not M.is_yaml_file() then
    return ""
  end
  
  local breadcrumb = M.get_yaml_breadcrumb()
  if breadcrumb then
    return M.format_breadcrumb(breadcrumb)
  end
  return ""
end

return M

local M = {}

function M.check()
  vim.health.start("YAML Breadcrumb")
  
  -- Check if plugin is loaded
  local ok, plugin = pcall(require, "yaml-breadcrumb")
  if not ok then
    vim.health.error("Plugin not loaded", {
      "Make sure 'yaml-breadcrumb' is properly installed",
      "Check your plugin configuration"
    })
    return
  end
  
  vim.health.ok("Plugin loaded successfully")
  
  -- Check plugin configuration
  if plugin.config then
    vim.health.ok("Configuration found")
    
    -- Check individual config options
    local config_checks = {
      { key = "enabled", expected = "boolean" },
      { key = "show_on_cursor_move", expected = "boolean" },
      { key = "separator", expected = "string" },
      { key = "virtual_text", expected = "boolean" },
    }
    
    for _, check in ipairs(config_checks) do
      local value = plugin.config[check.key]
      if value ~= nil and type(value) == check.expected then
        vim.health.ok(string.format("Config '%s': %s", check.key, tostring(value)))
      else
        vim.health.warn(string.format("Config '%s' has unexpected type or is nil", check.key))
      end
    end
  else
    vim.health.error("No configuration found")
  end
  
  -- Check if current file is YAML
  local current_file = vim.fn.expand("%:t")
  if current_file:match("%.ya?ml$") then
    vim.health.ok("Current file is YAML: " .. current_file)
    
    -- Test YAML parsing on current buffer
    local breadcrumb = plugin.get_yaml_breadcrumb()
    if breadcrumb then
      vim.health.ok("YAML structure detected successfully")
      vim.health.info("Current breadcrumb: " .. plugin.format_breadcrumb(breadcrumb))
    else
      vim.health.warn("No YAML structure found at cursor position")
    end
  else
    vim.health.info("Current file is not YAML (this is normal if you're not editing YAML)")
  end
  
  -- Check Neovim version compatibility
  local nvim_version = vim.version()
  if vim.version.cmp(nvim_version, {0, 8, 0}) >= 0 then
    vim.health.ok("Neovim version: " .. tostring(nvim_version) .. " (compatible)")
  else
    vim.health.error("Neovim version too old", {
      "Current: " .. tostring(nvim_version),
      "Required: >= 0.8.0",
      "Please upgrade Neovim"
    })
  end
  
  -- Check for required APIs
  local required_apis = {
    { name = "nvim_create_namespace", func = vim.api.nvim_create_namespace },
    { name = "nvim_buf_set_extmark", func = vim.api.nvim_buf_set_extmark },
    { name = "nvim_create_user_command", func = vim.api.nvim_create_user_command },
    { name = "nvim_create_augroup", func = vim.api.nvim_create_augroup },
  }
  
  for _, api in ipairs(required_apis) do
    if api.func then
      vim.health.ok("API available: " .. api.name)
    else
      vim.health.error("Missing API: " .. api.name, {
        "This API is required for the plugin to work",
        "Please upgrade Neovim"
      })
    end
  end
  
  -- Check keymaps
  local keymaps = vim.api.nvim_get_keymap("n")
  local our_keymaps = {}
  for _, map in ipairs(keymaps) do
    if map.desc and map.desc:match("YAML breadcrumb") then
      table.insert(our_keymaps, map.lhs)
    end
  end
  
  if #our_keymaps > 0 then
    vim.health.ok("Keymaps registered: " .. table.concat(our_keymaps, ", "))
  else
    vim.health.warn("No keymaps found", {
      "Plugin keymaps might not be set up",
      "Try calling setup() function"
    })
  end
  
  -- Check user commands
  local commands = vim.api.nvim_get_commands({})
  local our_commands = {}
  for name, _ in pairs(commands) do
    if name:match("^YamlBreadcrumb") then
      table.insert(our_commands, name)
    end
  end
  
  if #our_commands > 0 then
    vim.health.ok("Commands registered: " .. table.concat(our_commands, ", "))
  else
    vim.health.warn("No user commands found", {
      "Plugin commands might not be set up",
      "Try calling setup() function"
    })
  end
  
  -- Performance check
  local start_time = vim.loop.hrtime()
  for i = 1, 100 do
    plugin.get_yaml_breadcrumb()
  end
  local end_time = vim.loop.hrtime()
  local duration_ms = (end_time - start_time) / 1000000
  
  if duration_ms < 50 then
    vim.health.ok(string.format("Performance: %.2fms for 100 breadcrumb calculations", duration_ms))
  elseif duration_ms < 200 then
    vim.health.warn(string.format("Performance: %.2fms for 100 breadcrumb calculations (acceptable but slow)", duration_ms))
  else
    vim.health.error(string.format("Performance: %.2fms for 100 breadcrumb calculations (too slow)", duration_ms), {
      "Plugin might be too slow for large files",
      "Consider optimizing or disabling auto-update"
    })
  end
end

return M

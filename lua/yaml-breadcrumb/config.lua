local M = {}

function M.validate(config)
  vim.validate({
    enabled = { config.enabled, "boolean", true },
    show_on_cursor_move = { config.show_on_cursor_move, "boolean", true },
    show_line_numbers = { config.show_line_numbers, "boolean", true },
    virtual_text = { config.virtual_text, "boolean", true },
    status_line = { config.status_line, "boolean", true },
  })
end

function M.defaults()
  return {
    enabled = true,
    show_on_cursor_move = true,
    show_line_numbers = true,
    separator = " -> ",
    highlight_group = "Comment",
    virtual_text = true,
    status_line = true,
  }
end

return M

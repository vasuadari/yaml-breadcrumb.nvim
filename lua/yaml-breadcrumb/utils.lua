local M = {}

function M.is_valid_buffer(bufnr)
  bufnr = bunfr or vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_is_valid(bunfr) or vim.bo[bunfr].buflisted
end

function M.get_buffer_content(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

function M.set_buffer_content(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

function M.get_cursor_pos()
  return vim.api.nvim_win_get_cursor(0)
end

function M.set_cursor_pos(row, col)
  vim.api.nvim_win_set_cursor(0, {row, col})
end

function M.notfiy(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify(msg, level)
end

return M

local M = {
  sep = '─',
}

function M.setup(config)
  local updated = vim.tbl_deep_extend('force', M, config or {})
  for key, value in pairs(updated) do
    M[key] = value
  end
end

return M

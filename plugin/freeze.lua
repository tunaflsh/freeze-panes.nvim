local freeze

vim.api.nvim_create_user_command('Freeze', function(o)
  if freeze and vim.api.nvim_win_is_valid(freeze) then
    vim.api.nvim_win_close(freeze, true)
    vim.api.nvim_del_augroup_by_name('freeze')
    return
  end

  local buf = vim.fn.bufnr()
  local win = vim.fn.win_getid()
  local height = o.line2 - o.line1 + 1

  freeze = vim.api.nvim_open_win(0, false, {
    relative = 'win',
    win = win,
    row = 0,
    col = 0,
    width = vim.api.nvim_win_get_width(0),
    height = height,
    border = { '', '', '', '', '═', '═', '═', '' },
    focusable = false,
    noautocmd = true,
    zindex = 99,
  })

  vim.api.nvim_create_augroup('freeze', {})
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = 'freeze',
    buf = buf,
    callback = function()
      vim.api.nvim_win_set_config(freeze, {
        hide = win == vim.fn.win_getid() and vim.fn.winline() <= height,
      })
    end,
  })
  vim.api.nvim_create_autocmd('WinResized', {
    group = 'freeze',
    callback = function()
      vim.api.nvim_win_set_config(freeze, { width = vim.api.nvim_win_get_width(win) })
    end,
  })
  vim.api.nvim_create_autocmd('WinScrolled', {
    group = 'freeze',
    callback = function()
    end,
  })
end, {
  range = true,
  desc = 'Freeze lines in range on top of the window',
})

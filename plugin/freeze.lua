local config = require('freeze')
local freeze = {}

vim.api.nvim_create_user_command('Freeze', function(o)
  local buf = vim.fn.bufnr()
  local win = vim.fn.win_getid()
  local height = o.line2 - o.line1 + 1

  if freeze[win] and vim.api.nvim_win_is_valid(freeze[win]) then
    vim.api.nvim_win_close(freeze[win], true)
    if o.range == 0 then
      return
    end
  end

  freeze[win] = vim.api.nvim_open_win(0, false, {
    relative = 'win',
    win = win,
    row = 0,
    col = 0,
    width = vim.api.nvim_win_get_width(0),
    height = height,
    border = { '', '', '', '', '', config.sep, '', '' },
    focusable = false,
    noautocmd = true,
    zindex = 99,
  })
  vim.api.nvim_win_call(freeze[win], function()
    vim.api.nvim_win_set_cursor(0, { o.line1, 0 })
    vim.fn.winrestview({ topline = o.line1 })
  end)

  local group = vim.api.nvim_create_augroup('freeze.' .. win, {})
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buf = buf,
    callback = function()
      vim.api.nvim_win_set_config(freeze[win], {
        hide = win == vim.fn.win_getid() and vim.fn.winline() <= height + math.min(1, #config.sep),
      })
    end,
  })
  vim.api.nvim_create_autocmd('WinResized', {
    group = group,
    pattern = tostring(win),
    callback = function()
      vim.api.nvim_win_set_config(freeze[win], { width = vim.api.nvim_win_get_width(win) })
    end,
  })
  vim.api.nvim_create_autocmd('WinScrolled', {
    group = group,
    pattern = tostring(win),
    callback = function(a)
      if vim.v.event[a.match].leftcol ~= 0 then
        local leftcol = vim.fn.getwininfo(win)[1].leftcol
        vim.api.nvim_win_call(freeze[win], function()
          vim.fn.winrestview({ leftcol = leftcol })
        end)
      end
    end,
  })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = { tostring(win), tostring(freeze[win]) },
    callback = function()
      vim.api.nvim_win_close(freeze[win], false)
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
end, {
  range = true,
  desc = 'Freeze lines in range on top of the window',
})

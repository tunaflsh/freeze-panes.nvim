local config = require('freeze-panes')
local freeze = { [''] = {}, ['V'] = {} }

for _, dir in ipairs({ '', 'V' }) do
  -- local dir = direction
  vim.api.nvim_create_user_command(
    dir .. 'Freeze',
    function(o)
      local buf = vim.fn.bufnr()
      local win = vim.fn.win_getid()

      if freeze[dir][win] and vim.api.nvim_win_is_valid(freeze[dir][win]) then
        vim.api.nvim_win_close(freeze[dir][win], true)
        if o.range == 0 then
          return
        end
      end

      local border = { '', '', '', '', '', '', '', '' }
      local _, row1, col1 = unpack(vim.fn.getpos("'<"))
      local _, row2, col2 = unpack(vim.fn.getpos("'>"))
      local wininfo = vim.fn.getwininfo(win)[1]
      local width, height
      if dir == 'V' then
        if o.range == 0 then
          _, col1 = unpack(vim.api.nvim_win_get_cursor(win))
          col2 = col1
        elseif row1 ~= o.line1 or row2 ~= o.line2 then
          col1, col2 = o.line1 - 1, o.line2 - 1
        else
          col1, col2 = col1 - 1, col2 - 1
        end
        row1 = wininfo.topline
        border[4] = config.sep[dir]
        width = col2 - col1 + 1
        height = wininfo.height
      else
        if row1 ~= o.line1 or row2 ~= o.line2 then
          row1, row2 = o.line1, o.line2
        end
        col1 = wininfo.leftcol
        border[6] = config.sep[dir]
        width = wininfo.width - wininfo.textoff
        height = row2 - row1 + 1
      end

      freeze[dir][win] = vim.api.nvim_open_win(buf, false, {
        win = win,
        relative = 'win',
        row = 0,
        col = wininfo.textoff,
        style = 'minimal',
        width = width,
        height = height,
        border = border,
        focusable = false,
        noautocmd = true,
        zindex = dir == 'V' and 49 or 50,
      })
      vim.wo[freeze[dir][win]].signcolumn = 'no'
      if dir == '' then
        vim.wo[freeze[dir][win]].foldlevel = 99
      end
      vim.api.nvim_win_call(freeze[dir][win], function()
        vim.api.nvim_win_set_cursor(freeze[dir][win], { row1, col1 })
        vim.fn.winrestview({ topline = row1, leftcol = col1 })
      end)

      local group = vim.api.nvim_create_augroup('freeze.' .. freeze[dir][win], {})
      vim.api.nvim_create_autocmd('CursorMoved', {
        group = group,
        buf = buf,
        callback = function()
          local hide
          if win ~= vim.fn.win_getid() then
            return
          elseif dir == 'V' then
            local w = vim.fn.getwininfo(win)[1]
            hide = vim.fn.wincol() <= width + math.min(1, #config.sep[dir]) + w.textoff
          else
            hide = vim.fn.winline() <= height + math.min(1, #config.sep[dir])
          end
          vim.api.nvim_win_set_config(freeze[dir][win], { hide = hide })
        end,
      })
      vim.api.nvim_create_autocmd('WinResized', {
        group = group,
        callback = function()
          if not vim.list_contains(vim.v.event.windows, win) then
            return
          end
          local w = vim.fn.getwininfo(win)[1]
          if dir == 'V' then
            vim.api.nvim_win_set_config(freeze[dir][win], { height = w.height })
          else
            vim.api.nvim_win_set_config(freeze[dir][win], { width = w.width - w.textoff })
          end
        end,
      })
      vim.api.nvim_create_autocmd('WinScrolled', {
        group = group,
        callback = function()
          local event = vim.v.event[tostring(win)]
          if not event then
            return
          end
          if dir == 'V' and event.topline ~= 0 then
            local w = vim.fn.getwininfo(win)[1]
            vim.api.nvim_win_call(freeze[dir][win], function()
              vim.api.nvim_win_set_cursor(freeze[dir][win], { w.topline, col1 })
              vim.fn.winrestview({ topline = w.topline })
            end)
          elseif dir == '' and event.leftcol ~= 0 then
            local w = vim.fn.getwininfo(win)[1]
            vim.api.nvim_win_call(freeze[dir][win], function()
              vim.fn.winrestview({ leftcol = w.leftcol })
            end)
          end
        end,
      })

      local textoff_updater = vim.uv.new_timer()
      if textoff_updater then
        local textoff = wininfo.textoff
        textoff_updater:start(150, 150, vim.schedule_wrap(function()
          local w = vim.fn.getwininfo(win)[1]
          if textoff ~= w.textoff then
            textoff = w.textoff
            vim.api.nvim_win_set_config(freeze[dir][win], {
              win = win,
              relative = 'win',
              row = 0,
              col = w.textoff,
              width = dir == '' and w.width - w.textoff or nil,
            })
          end
        end))
      end

      vim.api.nvim_create_autocmd('WinClosed', {
        group = group,
        pattern = { tostring(win), tostring(freeze[dir][win]) },
        callback = function()
          vim.api.nvim_win_close(freeze[dir][win], false)
          vim.api.nvim_del_augroup_by_id(group)
          if textoff_updater then
            textoff_updater:stop()
            textoff_updater:close()
          end
        end,
      })
    end,
    {
      range = true,
      desc = 'Freeze lines in range on top of the window',
    }
  )
end

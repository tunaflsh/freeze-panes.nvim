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
      vim.wo[freeze[dir][win]].foldmethod = 'manual'
      if dir == '' then
        vim.wo[freeze[dir][win]].foldenable = false
      end
      vim.api.nvim_win_call(freeze[dir][win], function()
        vim.api.nvim_win_set_cursor(freeze[dir][win], { row1, col1 })
        vim.fn.winrestview({ topline = row1, leftcol = col1 })
      end)

      local group = vim.api.nvim_create_augroup('freeze.' .. freeze[dir][win], {})
      vim.api.nvim_create_autocmd('WinClosed', {
        group = group,
        pattern = { tostring(win), tostring(freeze[dir][win]) },
        callback = function()
          vim.api.nvim_win_close(freeze[dir][win], false)
          vim.api.nvim_del_augroup_by_id(group)
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
          elseif dir == 'V' and event.topline ~= 0 then
            local w = vim.fn.getwininfo(win)[1]
            vim.api.nvim_win_call(freeze[dir][win], function()
              vim.api.nvim_win_set_cursor(freeze[dir][win], { w.topline, col1 })
              vim.fn.winrestview({ topline = w.topline, leftcol = col1 })
            end)
          elseif dir == '' and event.leftcol ~= 0 then
            local w = vim.fn.getwininfo(win)[1]
            vim.api.nvim_win_call(freeze[dir][win], function()
              vim.fn.winrestview({ topline = row1, leftcol = w.leftcol })
            end)
          end
        end,
      })

      vim.api.nvim_create_autocmd('CursorMoved', {
        group = group,
        callback = function()
          if win ~= vim.fn.win_getid() then
            return
          end

          local hide
          local w = vim.fn.getwininfo(win)[1]
          if buf ~= vim.api.nvim_win_get_buf(win) then
            hide = true
          elseif vim.fn.foldclosed('.') ~= -1 then
          elseif dir == 'V' then
            hide = vim.fn.wincol() <= width + math.min(1, #config.sep[dir]) + w.textoff
          else
            hide = vim.fn.winline() <= height + math.min(1, #config.sep[dir])
          end

          vim.api.nvim_win_set_config(freeze[dir][win], {
            win = win,
            relative = 'win',
            row = 0,
            col = w.textoff,
            width = dir == '' and w.width - w.textoff or nil,
            hide = hide
          })

          if not hide and dir == 'V' then
            local lnum = vim.api.nvim_buf_line_count(buf)
            local folds = {}
            vim.api.nvim_win_call(win, function()
              local line = 1
              while line <= lnum do
                local open = vim.fn.foldclosed(line)
                if open ~= -1 then
                  local close = vim.fn.foldclosedend(line)
                  table.insert(folds, { open, close })
                  line = close
                end
                line = line + 1
              end
            end)

            vim.api.nvim_win_call(freeze[dir][win], function()
              local skip = true
              local line = 1
              for _, fold in ipairs(folds) do
                if fold[1] ~= vim.fn.foldclosed(fold[1]) then
                  skip = false break
                elseif fold[2] ~= vim.fn.foldclosed(fold[1]) then
                  skip = false break
                elseif line < fold[1]
                  and vim.iter(vim.fn.range(line, fold[1] - 1)):any(function(l)
                    return vim.fn.foldclosed(l) ~= -1
                  end) then
                  skip = false break
                end
                line = fold[2] + 1
              end
              if not skip then
              elseif line >= lnum then
                return
              elseif
                vim.iter(vim.fn.range(line, lnum)):all(function(l)
                  return vim.fn.foldclosed(l) == -1
                end) then
                return
              end

              vim.cmd('normal! zE')
              line = 1
              for _, fold in ipairs(folds) do
                pcall(vim.cmd, ('%d,%dfoldopen!'):format(line, fold[2]))
                vim.cmd(('%d,%dfold'):format(fold[1], fold[2]))
                line = fold[2] + 1
              end
              pcall(vim.cmd, ('%d,$foldopen!'):format(line))

              vim.api.nvim_win_set_cursor(freeze[dir][win], { w.topline, col1 })
              vim.fn.winrestview({ topline = w.topline, leftcol = col1 })
            end)
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

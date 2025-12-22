
vim.api.nvim_create_user_command('Zen', function()
  local padding_width = math.floor((vim.o.columns - vim.o.textwidth) / 4 - 1)
  local padding_bufnr = nil
  local padding_winid = nil

  -- Find if a window with buffer name "_padding_" already exists
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match '_padding_$' then
      padding_bufnr = buf
      padding_winid = win
      break
    end
  end

  if padding_winid then
    -- Just resize the existing padding window
    vim.api.nvim_set_current_win(padding_winid)
    vim.cmd('vertical resize ' .. padding_width)
    -- Go back to previous window
    vim.cmd 'wincmd p'
  else
    -- Create a new left split for padding
    vim.cmd(string.format('topleft %dvsplit _padding_', padding_width))
    local pad_buf = vim.api.nvim_get_current_buf()

    -- Make it unmodifiable and blank
    vim.api.nvim_buf_set_option(pad_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(pad_buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(pad_buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(pad_buf, 'modifiable', false)

    -- Return to previous window
    vim.cmd 'wincmd p'
  end
end, {})

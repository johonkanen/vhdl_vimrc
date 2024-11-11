return {
  {
    'godlygeek/tabular',
    config = function()
      -- Map <S-Tab> to trigger the Tabular command
      vim.keymap.set('n', '<S-Tab>', function()
        -- This simulates entering command mode and typing :Tabularize/Tab
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":Tab /", true, false, true), 'n', false)
      end, { noremap = true, silent = true })
    end,
  },
}

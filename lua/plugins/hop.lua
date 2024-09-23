return {
    'smoka7/hop.nvim',
    version = "*",
    opts = {
        keys = 'etovxqpdygfblzhckisuran'
    },

    vim.api.nvim_set_keymap('n', 'W', ':HopWordAC<CR>', { noremap = true, silent = true }),
    vim.api.nvim_set_keymap('n', 'B', ':HopWordBC<CR>', { noremap = true, silent = true })
}

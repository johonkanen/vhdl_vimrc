vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
-- vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "120"

-- Hide ignored files in netrw
vim.g.netrw_liststyle = 3 -- Use tree-style view
vim.g.netrw_banner = 1 -- Hide banner
vim.g.netrw_keepdir = 1 -- Automatically change to directory opened in netrw

-- set blinking highlight on cursor
vim.opt.guicursor = "n-v-c:block-blinkon1-blinkoff1-blinkwait250-Cursor/lCursor,i:ver25-blinkon1-blinkoff1-blinkwait250-Cursor/lCursor"

-- Copy with Ctrl+Insert
vim.api.nvim_set_keymap('n', '<C-Insert>', '"+y', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<C-Insert>', '"+y', { noremap = true, silent = true })

-- Paste with Shift+Insert
vim.api.nvim_set_keymap('n', '<S-Insert>', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<S-Insert>', '<C-R>+', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<C-v>', '<C-v>', {noremap = true, silent = true})

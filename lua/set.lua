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

vim.opt.colorcolumn = "80"

-- Hide ignored files in netrw
vim.g.netrw_liststyle = 3 -- Use tree-style view
vim.g.netrw_banner = 1 -- Hide banner
vim.g.netrw_keepdir = 1 -- Automatically change to directory opened in netrw

-- set blinking highlight on cursor
vim.opt.guicursor = "n-v-c:block-blinkon1-blinkoff1-blinkwait250-Cursor/lCursor,i:ver25-blinkon1-blinkoff1-blinkwait250-Cursor/lCursor"

-- Hide files listed in .gitignore or common patterns like .git, node_modules, etc.
-- vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
-- vim.g.netrw_list_hide = vim.g.netrw_list_hide .. [[,\(^\|\s\s\)\zsnode_modules]]
-- vim.g.netrw_list_hide = vim.g.netrw_list_hide .. [[,\(^\|\s\s\)\zstarget]]
-- vim.g.netrw_list_hide = vim.g.netrw_list_hide .. [[,\(^\|\s\s\)\zsdist]]
-- vim.g.netrw_list_hide = vim.g.netrw_list_hide .. [[,\(^\|\s\s\)\zsgit]]

-- Function to hide git ignored files in netrw
-- local function hide_gitignored_files()
--   local handle = io.popen('git ls-files -o -i --exclude-standard --directory')
--   if handle then
--     local result = handle:read("*a")
--     handle:close()
--     local files = vim.split(result, '\n')
--     for _, file in ipairs(files) do
--       if file ~= '' then
--         vim.o.wildignore = vim.o.wildignore .. ',' .. file
--       end
--     end
--   end
-- end
--
-- -- Automatically run when netrw is opened
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "netrw",
--   callback = hide_gitignored_files
-- })




vim.g.mapleader = " "
-- Open netrw in the current file's directory with the cursor on that file.
vim.keymap.set("n", "<leader>pv", function()
    local file = vim.fn.expand("%:t")
    vim.cmd.Ex()
    if file ~= "" then
        vim.fn.search([[\V]] .. vim.fn.escape(file, [[\]]), "cw")
    end
end, { desc = "Explore (netrw) at current file" })
vim.keymap.set("n", "<leader>vs", vim.cmd.vs)
vim.keymap.set("n", "<leader>sp", vim.cmd.sp)


-- map alt+hjkl to move between splits
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap('n', '<A-h>', '<C-w>h', opts)
vim.api.nvim_set_keymap('n', '<A-j>', '<C-w>j', opts)
vim.api.nvim_set_keymap('n', '<A-k>', '<C-w>k', opts)
vim.api.nvim_set_keymap('n', '<A-l>', '<C-w>l', opts)

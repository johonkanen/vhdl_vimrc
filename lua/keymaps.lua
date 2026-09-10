
vim.g.mapleader = " "
-- Open netrw with the cursor on the current file. In a project (cwd set by
-- vim-rooter) it opens the tree at the project root and expands every
-- ancestor directory down to the file, so it reads at a glance where the
-- file lives even in a deep repo; otherwise it just opens the file's own
-- directory, as before.
local function netrw_tree_indent(line)
    local depth = 0
    while line:sub(depth * 2 + 1, depth * 2 + 2) == "| " do
        depth = depth + 1
    end
    return depth
end

local function netrw_expand_current_dir()
    local depth = netrw_tree_indent(vim.api.nvim_get_current_line())
    local next_line = vim.api.nvim_buf_get_lines(0, vim.fn.line("."), vim.fn.line(".") + 1, false)[1]
    if next_line and netrw_tree_indent(next_line) > depth then
        return -- already expanded
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
end

vim.keymap.set("n", "<leader>pv", function()
    local filepath = vim.fn.expand("%:p")
    if filepath == "" then
        vim.cmd.Ex()
        return
    end

    local root = vim.fn.getcwd()
    local under_root = vim.g.netrw_liststyle == 3 and filepath:sub(1, #root + 1) == root .. "/"
    if not under_root then
        vim.cmd.Ex()
        vim.fn.search([[\V]] .. vim.fn.escape(vim.fn.fnamemodify(filepath, ":t"), [[\]]), "cw")
        return
    end

    vim.cmd("Explore " .. vim.fn.fnameescape(root))
    local parts = vim.split(filepath:sub(#root + 2), "/", { plain = true })
    for i = 1, #parts - 1 do
        if vim.fn.search([[\V]] .. vim.fn.escape(parts[i], [[\]]) .. "/", "cW") == 0 then
            break
        end
        netrw_expand_current_dir()
    end
    vim.fn.search([[\V]] .. vim.fn.escape(parts[#parts], [[\]]), "cw")
end, { desc = "Explore (netrw) reveal current file" })
vim.keymap.set("n", "<leader>vs", vim.cmd.vs)
vim.keymap.set("n", "<leader>sp", vim.cmd.sp)


-- map alt+hjkl to move between splits
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap('n', '<A-h>', '<C-w>h', opts)
vim.api.nvim_set_keymap('n', '<A-j>', '<C-w>j', opts)
vim.api.nvim_set_keymap('n', '<A-k>', '<C-w>k', opts)
vim.api.nvim_set_keymap('n', '<A-l>', '<C-w>l', opts)

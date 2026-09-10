
vim.g.mapleader = " "
-- Find the nearest ancestor directory of `filepath` containing one of
-- vim-rooter's markers. Computed directly from the file's own path rather
-- than trusting vim.fn.getcwd() -- vim-rooter caches its result per buffer
-- (b:rootDir) and only recomputes on BufEnter/BufReadPost, so the global cwd
-- can still reflect a previous buffer's project (e.g. right after Telescope
-- hands off a freshly opened file) when this key is pressed.
local ROOT_MARKERS = { ".git", "Makefile", "package.json" }
local function project_root(filepath)
    local dir = vim.fn.fnamemodify(filepath, ":h")
    while true do
        for _, marker in ipairs(ROOT_MARKERS) do
            if vim.fn.getftype(dir .. "/" .. marker) ~= "" then
                return dir
            end
        end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then
            return nil
        end
        dir = parent
    end
end

-- Open netrw with the cursor on the current file. In a project it opens the
-- tree at the project root and expands every ancestor directory down to the
-- file, so it reads at a glance where the file lives even in a deep repo
-- (e.g. inside a git submodule); otherwise it just opens the file's own
-- directory, as before.
local function netrw_tree_indent(line)
    local depth = 0
    while line:sub(depth * 2 + 1, depth * 2 + 2) == "| " do
        depth = depth + 1
    end
    return depth
end

-- Match a netrw tree-listing entry exactly: preceded by start-of-line or a
-- "| " indent marker, and running to end-of-line -- so e.g. "ode_pkg.vhd"
-- doesn't also match inside "adaptive_ode_pkg.vhd". (`\V` disables Vim's
-- regex specials INCLUDING the `^`/`$` anchors, so escape by hand instead.)
local NETRW_MAGIC_CHARS = ".*\\^$~["
local function netrw_pattern(name, suffix)
    return [[\(^\|\s\)]] .. vim.fn.escape(name, NETRW_MAGIC_CHARS) .. (suffix or "") .. "$"
end

-- Toggle (expand/collapse) the directory under the cursor by calling
-- netrw's own <CR> handler directly. Simulating an <Enter> keypress here
-- (nvim_feedkeys) is unreliable immediately after some plugins (e.g.
-- Telescope) hand off the buffer -- it can throw a spurious "E21: Cannot
-- make changes" and leave the directory collapsed.
local function netrw_toggle_current_dir()
    local ok = pcall(function()
        local m = vim.fn.maparg("<CR>", "n", false, true)
        if m.rhs == "<Plug>NetrwLocalBrowseCheck" then
            m = vim.fn.maparg("<Plug>NetrwLocalBrowseCheck", "n", false, true)
        end
        local cmd = m.rhs:gsub("<SID>", "<SNR>" .. m.sid .. "_")
        cmd = cmd:gsub("^:", ""):gsub("<[Cc]%-[Uu]>", ""):gsub("<[Cc][Rr]>$", "")
        vim.cmd(cmd)
    end)
    if not ok then -- fall back to a simulated keypress if netrw's internals ever change
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
    end
end

local function netrw_expand_current_dir()
    local depth = netrw_tree_indent(vim.api.nvim_get_current_line())
    local next_line = vim.api.nvim_buf_get_lines(0, vim.fn.line("."), vim.fn.line(".") + 1, false)[1]
    if next_line and netrw_tree_indent(next_line) > depth then
        return -- already expanded
    end
    netrw_toggle_current_dir()
end

vim.keymap.set("n", "<leader>pv", function()
    local filepath = vim.fn.expand("%:p")
    if filepath == "" then
        vim.cmd.Ex()
        return
    end

    local root = vim.g.netrw_liststyle == 3 and project_root(filepath) or nil
    if not root then
        vim.cmd.Ex()
        vim.fn.search(netrw_pattern(vim.fn.fnamemodify(filepath, ":t")), "cw")
        return
    end

    vim.cmd("Explore " .. vim.fn.fnameescape(root))
    local parts = vim.split(filepath:sub(#root + 2), "/", { plain = true })
    for i = 1, #parts - 1 do
        if vim.fn.search(netrw_pattern(parts[i], "/"), "cW") == 0 then
            break
        end
        netrw_expand_current_dir()
    end
    vim.fn.search(netrw_pattern(parts[#parts]), "cw")
end, { desc = "Explore (netrw) reveal current file" })
vim.keymap.set("n", "<leader>vs", vim.cmd.vs)
vim.keymap.set("n", "<leader>sp", vim.cmd.sp)


-- map alt+hjkl to move between splits
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap('n', '<A-h>', '<C-w>h', opts)
vim.api.nvim_set_keymap('n', '<A-j>', '<C-w>j', opts)
vim.api.nvim_set_keymap('n', '<A-k>', '<C-w>k', opts)
vim.api.nvim_set_keymap('n', '<A-l>', '<C-w>l', opts)

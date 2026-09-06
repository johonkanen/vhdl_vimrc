-- Build the slug Claude Code uses for the current working directory's
-- session folder: every "/" and "." in the path becomes "-".
local function session_dir()
    local slug = vim.fn.getcwd():gsub("[/.]", "-")
    return vim.fn.expand("~/.claude/projects/") .. slug
end

-- Read the first human-typed prompt from a session .jsonl for use as a label.
local function session_preview(path)
    local fd = io.open(path, "r")
    if not fd then
        return nil
    end
    local preview
    for line in fd:lines() do
        local ok, entry = pcall(vim.json.decode, line)
        if ok and entry.type == "user" and entry.promptSource == "typed" then
            local content = entry.message and entry.message.content
            if type(content) == "string" then
                preview = content
                break
            end
        end
    end
    fd:close()
    return preview
end

-- Collect sessions for the current project, newest first.
local function collect_sessions()
    local files = vim.fn.glob(session_dir() .. "/*.jsonl", false, true)
    table.sort(files, function(a, b)
        return vim.fn.getftime(a) > vim.fn.getftime(b)
    end)
    local items = {}
    for _, path in ipairs(files) do
        local preview = (session_preview(path) or "(no preview)"):gsub("%s+", " "):sub(1, 80)
        table.insert(items, {
            id = vim.fn.fnamemodify(path, ":t:r"),
            label = string.format("%s  %s", os.date("%Y-%m-%d %H:%M", vim.fn.getftime(path)), preview),
        })
    end
    return items
end

-- Show a picker of past sessions; resume the chosen one.
local function pick_session(items)
    items = items or collect_sessions()
    if vim.tbl_isempty(items) then
        vim.notify("No Claude sessions for " .. vim.fn.getcwd(), vim.log.levels.INFO)
        return
    end
    vim.ui.select(items, {
        prompt = "Claude sessions",
        format_item = function(item)
            return item.label
        end,
    }, function(choice)
        if choice then
            vim.cmd("ClaudeCode --resume " .. choice.id)
        end
    end)
end

-- On startup, if Neovim opened without a file and this project has past
-- Claude sessions, offer to resume one. Disable with `vim.g.claude_session_prompt = false`.
local function maybe_prompt_on_startup()
    if vim.g.claude_session_prompt == false then
        return
    end
    if #vim.api.nvim_list_uis() == 0 then
        return -- headless
    end
    -- Only when Neovim opened on no file, or on a directory (e.g. `nvim .`).
    local args = vim.fn.argv()
    local opened_dir = #args == 1 and vim.fn.isdirectory(args[1]) == 1
    if (#args > 0 and not opened_dir) or vim.bo.filetype == "gitcommit" then
        return
    end
    -- Defer so vim-rooter has settled the cwd and the UI is ready.
    vim.schedule(function()
        local items = collect_sessions()
        if not vim.tbl_isempty(items) then
            pick_session(items)
        end
    end)
end

return {
    "coder/claudecode.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel", "ClaudeCodeAdd", "ClaudeCodeSend", "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny" },
    -- `config = true` runs require("claudecode").setup({})
    opts = {
        -- Use Neovim's built-in terminal (snacks.nvim is not installed).
        terminal = {
            provider = "native",
            split_side = "right",
            split_width_percentage = 0.35,
        },
    },
    -- Register the startup prompt even though the plugin itself loads lazily.
    init = function()
        vim.api.nvim_create_autocmd("VimEnter", {
            group = vim.api.nvim_create_augroup("claude_session_prompt", { clear = true }),
            callback = maybe_prompt_on_startup,
        })
        -- <C-q> leaves terminal mode in the Claude split; <Esc> stays reserved for Claude.
        vim.api.nvim_create_autocmd("TermOpen", {
            group = vim.api.nvim_create_augroup("claude_term_keys", { clear = true }),
            pattern = "term://*claude*",
            callback = function(ev)
                vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { buffer = ev.buf, desc = "Claude: exit terminal mode" })
            end,
        })
    end,
    -- `<leader>a` is taken by harpoon, so Claude lives under `<leader>c`.
    keys = {
        { "<leader>c", nil, desc = "Claude" },
        { "<leader>cc", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last Claude session" },
        { "<leader>cn", "<cmd>ClaudeCode<cr>", desc = "New Claude session" },
        { "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
        { "<leader>cr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude (built-in picker)" },
        { "<leader>cl", pick_session, desc = "List Claude sessions" },
        { "<leader>cm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
        { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
        { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
        { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
        { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
    },
}

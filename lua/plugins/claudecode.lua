-- Claude Code repaints its transcript in place and keeps no terminal
-- scrollback, so Neovim's own scroll keys have nothing to move through.
-- Instead, forward scroll input to Claude, which scrolls its own view.
-- (Verified: Claude responds to xterm PageUp/PageDown and SGR wheel events.)
local function claude_scroller(buf)
    local job = vim.b[buf].terminal_job_id
    local WHEEL_UP = "\27[<64;1;1M"
    local WHEEL_DOWN = "\27[<65;1;1M"
    local PAGE_UP = "\27[5~"
    local PAGE_DOWN = "\27[6~"
    return function(seq, count)
        if job then
            vim.fn.chansend(job, string.rep(seq, count or 1))
        end
    end,
        { wheel_up = WHEEL_UP, wheel_down = WHEEL_DOWN, page_up = PAGE_UP, page_down = PAGE_DOWN }
end

-- j/k in the Claude buffer move the cursor normally, but once it reaches the
-- 'scrolloff' zone at the top/bottom edge they scroll Claude's view instead --
-- mirroring how Neovim scrolls a normal buffer at the margins.
local function edge_motion(send, seq, dir)
    return function()
        local so = math.max(tonumber(vim.wo.scrolloff) or 0, 1)
        local wl = vim.fn.winline()
        local wh = vim.api.nvim_win_get_height(0)
        if dir == "up" and wl <= so + 1 then
            send(seq.wheel_up, 2)
        elseif dir == "down" and wl >= wh - so then
            send(seq.wheel_down, 2)
        else
            vim.cmd("normal! " .. (dir == "up" and "k" or "j"))
        end
    end
end

-- Build the slug Claude Code uses for the current working directory's
-- session folder: every "/" and "." in the path becomes "-".
local function session_dir()
    local slug = vim.fn.getcwd():gsub("[/.]", "-")
    return vim.fn.expand("~/.claude/projects/") .. slug
end

-- Custom session labels live next to the transcripts, keyed by session id.
local function labels_file()
    return session_dir() .. "/nvim-labels.json"
end

local function load_labels()
    local fd = io.open(labels_file(), "r")
    if not fd then
        return {}
    end
    local raw = fd:read("*a")
    fd:close()
    local ok, tbl = pcall(vim.json.decode, raw)
    return (ok and type(tbl) == "table") and tbl or {}
end

local function save_labels(tbl)
    local fd = io.open(labels_file(), "w")
    if not fd then
        vim.notify("Claude: could not write " .. labels_file(), vim.log.levels.ERROR)
        return
    end
    fd:write(vim.json.encode(tbl))
    fd:close()
end

-- Read the first human-typed prompt from a session .jsonl for use as a label.
local function session_preview(path)
    local fd = io.open(path, "r")
    if not fd then
        return nil
    end
    local preview
    for line in fd:lines() do
        local ok, entry = pcall(vim.json.decode, line, { luanil = { object = true, array = true } })
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
    local labels = load_labels()
    local items = {}
    for _, path in ipairs(files) do
        local id = vim.fn.fnamemodify(path, ":t:r")
        local preview = (session_preview(path) or "(no preview)"):gsub("%s+", " "):sub(1, 80)
        local custom = labels[id]
        table.insert(items, {
            id = id,
            custom = custom,
            preview = preview,
            label = string.format(
                "%s  %s",
                os.date("%Y-%m-%d %H:%M", vim.fn.getftime(path)),
                custom and ("★ " .. custom) or preview
            ),
        })
    end
    return items
end

-- Pick a session and give it (or clear) a custom label shown in the picker.
local function rename_session()
    local items = collect_sessions()
    if vim.tbl_isempty(items) then
        vim.notify("No Claude sessions for " .. vim.fn.getcwd(), vim.log.levels.INFO)
        return
    end
    vim.ui.select(items, {
        prompt = "Rename which session?",
        format_item = function(item)
            return item.label
        end,
    }, function(choice)
        if not choice then
            return
        end
        vim.ui.input({ prompt = "Label (empty to clear): ", default = choice.custom or "" }, function(input)
            if input == nil then
                return
            end
            input = vim.trim(input)
            local labels = load_labels()
            labels[choice.id] = input ~= "" and input or nil
            save_labels(labels)
            vim.notify(input ~= "" and ('Claude session labelled "' .. input .. '"') or "Claude session label cleared")
        end)
    end)
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

-- Pick a session and permanently delete its transcript (and any label).
local function delete_session()
    local items = collect_sessions()
    if vim.tbl_isempty(items) then
        vim.notify("No Claude sessions for " .. vim.fn.getcwd(), vim.log.levels.INFO)
        return
    end
    vim.ui.select(items, {
        prompt = "Delete which session?",
        format_item = function(item)
            return item.label
        end,
    }, function(choice)
        if not choice then
            return
        end
        local name = choice.custom or choice.preview
        if vim.fn.confirm('Delete Claude session "' .. name .. '" permanently?', "&Yes\n&No", 2) ~= 1 then
            return
        end
        local ok, err = os.remove(session_dir() .. "/" .. choice.id .. ".jsonl")
        local labels = load_labels()
        if labels[choice.id] ~= nil then
            labels[choice.id] = nil
            save_labels(labels)
        end
        if ok then
            vim.notify("Claude session deleted")
        else
            vim.notify("Claude: " .. (err or "could not delete session"), vim.log.levels.ERROR)
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
            -- Land in normal mode when focusing the split, so all the usual
            -- Neovim navigation works on Claude's output. Press `i` to type.
            auto_insert = false,
        },
    },
    -- Register the startup prompt even though the plugin itself loads lazily.
    init = function()
        vim.api.nvim_create_autocmd("VimEnter", {
            group = vim.api.nvim_create_augroup("claude_session_prompt", { clear = true }),
            callback = maybe_prompt_on_startup,
        })
        vim.api.nvim_create_autocmd("TermOpen", {
            group = vim.api.nvim_create_augroup("claude_term_keys", { clear = true }),
            pattern = "term://*claude*",
            callback = function(ev)
                -- <C-q> leaves terminal mode in the Claude split; <Esc> stays reserved for Claude.
                vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { buffer = ev.buf, desc = "Claude: exit terminal mode" })
                -- <A-hjkl> jumps between splits even while typing in Claude (matches normal mode).
                for _, k in ipairs({ "h", "j", "k", "l" }) do
                    vim.keymap.set("t", "<A-" .. k .. ">", [[<C-\><C-n><C-w>]] .. k, { buffer = ev.buf })
                end
                -- In normal mode: h/l/w/b and friends move the cursor as usual;
                -- j/k move the cursor too but scroll Claude's transcript once it
                -- reaches the top/bottom margin. <C-e>/<C-y>, <C-d>/<C-u>,
                -- <C-f>/<C-b>, <PageUp>/<PageDown>, the wheel and gg/G scroll
                -- Claude directly (cursor stays put), like nvim scroll commands.
                local send, seq = claude_scroller(ev.buf)
                vim.keymap.set("n", "k", edge_motion(send, seq, "up"), { buffer = ev.buf })
                vim.keymap.set("n", "j", edge_motion(send, seq, "down"), { buffer = ev.buf })
                local nmaps = {
                    ["<C-y>"] = { seq.wheel_up, 1 },
                    ["<C-e>"] = { seq.wheel_down, 1 },
                    ["<C-u>"] = { seq.wheel_up, 12 },
                    ["<C-d>"] = { seq.wheel_down, 12 },
                    ["<C-b>"] = { seq.page_up, 1 },
                    ["<C-f>"] = { seq.page_down, 1 },
                    ["<PageUp>"] = { seq.page_up, 1 },
                    ["<PageDown>"] = { seq.page_down, 1 },
                    ["<ScrollWheelUp>"] = { seq.wheel_up, 3 },
                    ["<ScrollWheelDown>"] = { seq.wheel_down, 3 },
                    ["gg"] = { seq.page_up, 40 },
                    ["G"] = { seq.page_down, 40 },
                }
                for lhs, args in pairs(nmaps) do
                    vim.keymap.set("n", lhs, function()
                        send(args[1], args[2])
                    end, { buffer = ev.buf })
                end
                -- PageUp/PageDown scroll while still in terminal mode; <C-u>/<C-d> are
                -- left alone there since Claude uses <C-u> to clear the input line.
                for _, lhs in ipairs({ "<PageUp>", "<PageDown>" }) do
                    vim.keymap.set("t", lhs, function()
                        send(nmaps[lhs][1], nmaps[lhs][2])
                    end, { buffer = ev.buf })
                end
                -- Show the usage widget alongside Claude. Disable with `vim.g.claude_usage_widget = false`.
                if vim.g.claude_usage_widget ~= false then
                    require("claude_usage").open()
                end
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
        { "<leader>cR", rename_session, desc = "Rename a Claude session" },
        { "<leader>cD", delete_session, desc = "Delete a Claude session" },
        { "<leader>cu", function() require("claude_usage").toggle() end, desc = "Toggle Claude usage widget" },
        { "<leader>cm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
        { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
        { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
        { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
        { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
    },
}

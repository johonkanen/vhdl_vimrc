-- A small floating widget (top-right) showing the current Claude Code 5-hour
-- usage block: spend, tokens, and time until the block resets.
--
-- Data comes from `ccusage` (https://github.com/ryoppippi/ccusage), which reads
-- ~/.claude/projects/*.jsonl. A global `ccusage` binary is used if present,
-- otherwise `npx -y ccusage@latest`. Numbers are estimates, not official.

local M = {}
local uv = vim.uv or vim.loop

local REFRESH_MS = 30000 -- re-render (local countdown) cadence
local REFETCH_S = 55 -- re-run ccusage no more often than this

local state = {
    win = nil,
    buf = nil,
    timer = nil,
    job = nil, -- running ccusage vim.system handle
    fetching = false,
    fetched_at = 0,
    data = nil, -- { cost, tokens, remaining } | { error } | { idle }
}

vim.api.nvim_set_hl(0, "ClaudeUsage", { link = "NormalFloat", default = true })
vim.api.nvim_set_hl(0, "ClaudeUsageBorder", { link = "FloatBorder", default = true })

local function fmt_tokens(n)
    if n >= 1e6 then
        return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.0fk", n / 1e3)
    end
    return tostring(math.floor(n))
end

local function fmt_dur(secs)
    secs = math.max(secs, 0)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 then
        return string.format("%dh%02dm", h, m)
    end
    return string.format("%dm", m)
end

local function ccusage_cmd()
    if vim.fn.executable("ccusage") == 1 then
        return { "ccusage", "blocks", "--active", "--json" }
    end
    return { "npx", "-y", "ccusage@latest", "blocks", "--active", "--json" }
end

local function fetch()
    if state.fetching then
        return
    end
    if vim.fn.executable("ccusage") == 0 and vim.fn.executable("npx") == 0 then
        state.data = { error = "need ccusage or npx" }
        return
    end
    state.fetching = true
    state.job = vim.system(ccusage_cmd(), { text = true }, function(res)
        state.fetching = false
        state.job = nil
        if res.code ~= 0 then
            state.data = { error = "ccusage failed" }
        else
            -- luanil turns JSON null into Lua nil instead of the userdata
            -- vim.NIL, so a null "projection" (e.g. a block with no burn-rate
            -- estimate yet) can't be mistaken for a truthy table below.
            local ok, parsed =
                pcall(vim.json.decode, res.stdout or "", { luanil = { object = true, array = true } })
            local block = ok and parsed.blocks and parsed.blocks[1] or nil
            if block then
                state.data = {
                    cost = block.costUSD or 0,
                    tokens = block.totalTokens or 0,
                    remaining = (block.projection and block.projection.remainingMinutes or 0) * 60,
                }
                state.fetched_at = os.time()
            else
                state.data = { idle = true }
            end
        end
        vim.schedule(M.render)
    end)
end

local function lines()
    local d = state.data
    if not d then
        return { " Claude usage", " loading…" }
    end
    if d.error then
        return { " Claude usage", " " .. d.error }
    end
    if d.idle then
        return { " Claude usage", " no active block" }
    end
    local left = d.remaining - (os.time() - state.fetched_at)
    return {
        " Claude · 5h block",
        string.format(" $%.2f   %s tok", d.cost, fmt_tokens(d.tokens)),
        " resets in " .. fmt_dur(left),
    }
end

function M.render()
    if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
        return
    end
    local ls = lines()
    local width = 0
    for _, l in ipairs(ls) do
        width = math.max(width, vim.fn.strdisplaywidth(l))
    end
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, ls)
    vim.api.nvim_win_set_config(state.win, {
        relative = "editor",
        anchor = "NE",
        row = 1,
        col = vim.o.columns,
        width = width,
        height = #ls,
    })
end

function M.open()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        return
    end
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].bufhidden = "wipe"
    state.win = vim.api.nvim_open_win(state.buf, false, {
        relative = "editor",
        anchor = "NE",
        row = 1,
        col = vim.o.columns,
        width = 18,
        height = 2,
        focusable = false,
        style = "minimal",
        border = "rounded",
        noautocmd = true,
        zindex = 45,
    })
    vim.wo[state.win].winblend = 10
    vim.wo[state.win].winhighlight = "NormalFloat:ClaudeUsage,FloatBorder:ClaudeUsageBorder"

    local grp = vim.api.nvim_create_augroup("claude_usage_widget", { clear = true })
    vim.api.nvim_create_autocmd({ "VimResized", "TabEnter" }, {
        group = grp,
        callback = function()
            M.render()
        end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", { group = grp, callback = M.close })

    state.timer = uv.new_timer()
    state.timer:start(
        0,
        REFRESH_MS,
        vim.schedule_wrap(function()
            if os.time() - state.fetched_at >= REFETCH_S then
                fetch()
            end
            M.render()
        end)
    )
    fetch()
    M.render()
end

function M.close()
    if state.timer then
        state.timer:stop()
        state.timer:close()
        state.timer = nil
    end
    if state.job then
        pcall(function()
            state.job:kill("sigterm")
        end)
        state.job = nil
    end
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win, state.buf = nil, nil
    pcall(vim.api.nvim_del_augroup_by_name, "claude_usage_widget")
end

function M.toggle()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        M.close()
    else
        M.open()
    end
end

return M

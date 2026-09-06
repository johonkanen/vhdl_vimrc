return {
    "coder/claudecode.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- `config = true` runs require("claudecode").setup({})
    opts = {
        -- Use Neovim's built-in terminal (snacks.nvim is not installed).
        terminal = {
            provider = "native",
            split_side = "right",
            split_width_percentage = 0.35,
        },
    },
    -- `<leader>a` is taken by harpoon, so Claude lives under `<leader>c`.
    keys = {
        { "<leader>c", nil, desc = "Claude" },
        { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
        { "<leader>cf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
        { "<leader>cr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
        { "<leader>cC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
        { "<leader>cm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
        { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
        { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
        { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
        { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
    },
}

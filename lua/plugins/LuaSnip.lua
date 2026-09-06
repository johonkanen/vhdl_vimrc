return {
    {
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp",

        dependencies = { "rafamadriz/friendly-snippets" },

        config = function()
            local ls = require("luasnip")
            ls.filetype_extend("javascript", { "jsdoc" })

            -- Load friendly-snippets (VSCode-format, includes VHDL).
            require("luasnip.loaders.from_vscode").lazy_load()

            -- Add your custom 'mysnippets' folder
            local path = vim.fn.stdpath("config") .. "/mysnippets/"
            require("luasnip.loaders.from_lua").lazy_load({ paths = path })

            vim.keymap.set({"i"}, "<C-l>", function() ls.expand() end, {silent = true})

            -- Shift-Space: expand the snippet under the cursor, or jump to the
            -- next placeholder if one is active (matches the old basic-vim setup).
            -- Needs a terminal that reports <S-Space> distinctly (kitty keyboard
            -- protocol) -- kitty, wezterm, recent Windows Terminal, alacritty.
            vim.keymap.set({"i", "s"}, "<S-Space>", function()
                if ls.expand_or_jumpable() then
                    ls.expand_or_jump()
                end
            end, {silent = true})

            vim.keymap.set({"i", "s"}, "<C-s>;", function() ls.jump(1) end, {silent = true})
            -- vim.keymap.set({"i", "s"}, "<C-s>,", function() ls.jump(-1) end, {silent = true})

            vim.keymap.set({"i", "s"}, "<C-E>", function()
                if ls.choice_active() then
                    ls.change_choice(1)
                end
            end, {silent = true})
        end,
    }
}

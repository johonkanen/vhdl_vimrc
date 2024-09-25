return {
    'airblade/vim-rooter',
    config = function()
            -- Vim-rooter will automatically change the working directory to the project root
            vim.g.rooter_patterns = { '.git', 'Makefile', 'package.json' } -- Set the rooter patterns
            vim.g.rooter_silent_chdir = 1 -- Optional: Don't print messages when changing directories
    end,
}

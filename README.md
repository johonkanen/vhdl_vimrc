# vhdl_vimrc
my neovim configuration

Install through msys2

0. get git

1. get msys2
> https://www.msys2.org/

2. install clang and gcc
> pacman -S mingw-w64-x86_64-clang

2. install neovim using msys2
    > pacman -S mingw-w64-x86_64-neovim

3. create ~\AppData\Local\nvim and clone nvim configuration repository using
    > git clone https://github.com/johonkanen/vhdl_vimrc.git .\

4. open neovim using 
    > nvim .

Enjoy :)

## Claude Code

`lua/plugins/claudecode.lua` wires up [claudecode.nvim](https://github.com/coder/claudecode.nvim)
plus some extras: a session picker, a rename/delete flow, a top-right usage
widget, and normal-mode navigation inside the Claude split.

### Keymaps (`<leader>c`)

| Key | Action |
| --- | --- |
| `<leader>cc` | Continue the most recent session |
| `<leader>cn` | Start a new session |
| `<leader>cf` | Focus the Claude split |
| `<leader>cl` | List sessions for this project and resume one |
| `<leader>cr` | Claude's own `--resume` picker (inside the terminal) |
| `<leader>cR` | Rename the picked session (label shown in the list; empty clears) |
| `<leader>cD` | Delete the picked session (transcript + label, permanent) |
| `<leader>cu` | Toggle the usage widget |
| `<leader>cm` | Select the Claude model |
| `<leader>cb` | Add the current buffer to Claude's context |
| `<leader>cs` | Send the visual selection to Claude (visual mode) |
| `<leader>ca` | Accept the proposed diff |
| `<leader>cd` | Deny the proposed diff |

### Inside the Claude split

Focusing the split lands you in normal mode (press `i`/`a` to type a prompt).

| Key | Mode | Action |
| --- | --- | --- |
| `<C-q>` | terminal | Leave terminal mode (back to normal) |
| `<A-h/j/k/l>` | terminal | Jump to the split in that direction |
| `j` / `k` | normal | Move the cursor; scroll the transcript at the top/bottom margin |
| `<C-e>`/`<C-y>`, `<C-d>`/`<C-u>`, `<C-f>`/`<C-b>`, wheel, `gg`/`G` | normal | Scroll Claude's transcript |
| `<PageUp>` / `<PageDown>` | normal & terminal | Scroll Claude's transcript |

### Startup / behaviour

- Opening `nvim` with no file (or on a directory) in a project that has past
  sessions pops up the session picker. Disable with
  `vim.g.claude_session_prompt = false`.
- The usage widget opens automatically with the Claude split. Disable with
  `vim.g.claude_usage_widget = false`. It needs `ccusage` (global binary or
  `npx ccusage@latest`).
- Session labels are stored per project in
  `~/.claude/projects/<slug>/nvim-labels.json`.

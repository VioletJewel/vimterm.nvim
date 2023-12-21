# vimterm.nvim


## About

Make neovim's `:term` become vim's `:term`.

This plugin:
- adds a ['termwinkey'](https://vimhelp.org/options.txt.html#%27termwinkey%27)
  to neovim
    - eg, `<C-w>p` navigates to the previous window just like in normal mode
    - terminal mode automatically resumes when moving back to a terminal window
- automatically starts terminal mode on TermOpen
- provides the `:Sterminal` user command that works like vim's `:term` (see
  [Split Terminals](#split-terminals))
  - `:term`/`:vterm` also expand to `:Sterm`/`:vert Sterm` (see
    [Term and Vterm Hacks](#term-and-vterm-hacks))
- automatically closes the terminal window when the default 'shell' terminates
  "successfully"
- sets `b:vimterm_name` to a nicer name for use with 'statusline' (see
  [Statusline Name](#statusline-name))

tl;dr instead of `<C-\><C-n><C-w>p{do-work}<C-w>pi`, just do
`<C-w>p{do-work}<C-w>p`. `<C-w>` just works as expected™.

See [nvim](#neovim-terminal) vs [vim](#vim-terminal)
[Terminal Differences](#terminal-differences) and
[Typical Workflow](#typical-workflow).

## Installation

Ie, with [lazy.nvim](https://github.com/folke/lazy.nvim/):

```lua
{
  'VioletJewel/vimterm.nvim',
  config = { ... }
}
```

Alternatively, install it with a package manager, and then do something like the
following once it is loaded:

```lua
local vtok, vimterm = pcall(require, 'vimterm')
if vtok then
  vimterm.setup{ ... }
end
```

**Note:** Replace `...` with some or all of the modified
[Default Config](#default-config) below (or leave it empty).

**Note:** You must call `vimterm.setup()` directly (eg,
`require'vimterm'.setup()`) or indirectly (eg, lazy.nvim's `config = {}`).

### Default Config

```lua
{
  termwinkey = '<C-w>',
  autoclose = true,
  autostartinsert = true,
  abbrevhack = true,
}
```

| Option | Description |
| ------ | ----------- |
| `termwinkey` | similar to vim's ['termwinkey'](https://vimhelp.org/options.txt.html#%27termwinkey%27) |
| `autoclose` | should the terminal close if the default shell exited successfully |
| `autostartinsert` | should the terminal automatically `:startinsert` after opening |
| `abbrevhack` | should **vimtern.vim** auto-expand `:term` and `:vterm` to `:Sterm` and `:vert Sterm` using cabbrev hack |


## Split Terminals

`:Sterminal` opens a split terminal. This is how `:terminal` behaves in vim.

You can pass `{mods}` like `vertical`, `belowright`, `aboveleft`, `tab`, etc.
See
[`:command-modifiers`](https://neovim.io/doc/user/map.html#%3Acommand-modifiers).

`{cmd}` is an optional command that is forwarded to
[`:terminal`](https://neovim.io/doc/user/various.html#%3Aterminal). See the help
for more info about `{cmd}`

| Example | Description |
| ------- | ----------- |
| `:Sterm` | opens the default 'shell' in a horizontally split terminal |
| `:below vert Sterm` | opens the default 'shell' vertically split terminal on the right |
| `:Sterm python` | opens a python repl in a horizontally split terminal |
| `:tab Sterm` | opens a terminal in a new tab page |

### Term and Vterm Hacks

`:term` and `:vterm` also automagically expand to `:Sterm` and `:vert Sterm`
(resp.).

**Notes:**
- after you type ":term" and a space, `:term ` transforms instantly to `:Sterm `
  (because of using `:cabbrev`)
- you cannot use `{mods}` like you can with `:Sterminal` (ie, `:vert term` won't
  expand)
- these also have to be the first word in the cmdline (ie, neither `:  term` nor
  `:echo 'hi'|term` will work).


## Terminal Differences

Essentially, vim has a decent user experience out of the box, while neovim
expects you to use a plugin or make custom maps. Although this plugin resolves
these differences, there is [some divergence](#divergence).

### Neovim Terminal

In neovim, `:terminal` opens in the current window (not a split) in normal mode.
Also, neovim provides two terminal commands:
- [`t_CTRL-\_CTRL-N`](https://neovim.io/doc/user/intro.html#CTRL-%5C_CTRL-N): go
  to normal mode
- [`t_CTRL-\_CTRL-O`](https://neovim.io/doc/user/intro.html#CTRL-%5C_CTRL-O):
  temporarily insert normal mode (like
  [`i_CTRL-O`](https://neovim.io/doc/user/insert.html#i_CTRL-O))

This is limited and would cause a very noisy workflow without any customization.
Perhaps it is expected that you will use a plugin that manages terminals for you
(such as a pop-up terminal or a terminal similar to vscode's terminal on the
bottom) or use these two terminal commands to create your own custom mappings.

### Vim Terminal

In vim, `:terminal` opens in a split window and starts terminal mode by default.
Vim also has
[`t_CTRL-\_CTRL-N`](https://vimhelp.org/terminal.txt.html#t_CTRL-%5C_CTRL-N)
(there is no `t_CTRL-W_CTRL-O`) but also provides a handy
['termwinkey'](https://vimhelp.org/options.txt.html#%27termwinkey%27)). By
default, 'termwinkey' is `<C-w>`.

'termwinkey' is very handy because it allows you to perform actions from
terminal mode, navigate quickly to other windows or tab pages and resume
terminal mode when coming back to that terminal window, insert registers, and a
few other handy maps to tie up some loose ends. Here are the features of
'termwinkey' (`<C-w>` used as 'termwinkey', but it can be changed) when in
terminal mode:

| Term Cmd | Description | Vim Help |
| -------- | ----------- | -------- |
| `<C-w>N` | same as `<C-\><C-n>` | [`t_CTRL-W_N`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_N) |
| `<C-w><C-n>` | same as `<C-\><C-n>` and `<C-w>N` | [`t_CTRL-W_N`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_N) (same section as `<C-w>N`) |
| `<C-w>:{cmd}` | issue one-off ex `{cmd}` | [`t_CTRL-W_%`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_%3A) |
| `<C-w><C-w>` | move focus to the next window (replace this with any [`CTRL-W window command`](https://neovim.io/doc/user/vimindex.html#CTRL-W)) | [`t_CTRL-W_CTRL-W`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_CTRL-W) |
| `<C-w>[{count}]"{reg}` | insert `{reg}` `{count}` times (eg, `<C-w>2"+` to insert PRIMARY clipboard twice) | [`t_CTRL-W_quote`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_quote) |
| `<C-w>.` | insert literal `<C-w>` | [`t_CTRL-W_.`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_%2E) |
| `<C-w><C-\>` | insert literal `<C-\>` | [`t_CTRL-W_N`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_N) |
| `<C-w>[{count}]gt` | go to next tab page `{count}` times | [`t_CTRL-W_gt`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_gt)
| `<C-w>[{count}]gT` | go to previous tab page `{count}` times | [`t_CTRL-W_gt`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_gt)



## Statusline Name

The terminal name (%f in
['statusline'](https://neovim.io/doc/user/options.html#'statusline')) in neovim
is unpleasant to look at . This plugin sets `b:vimterm_name`. You can set 'statusline'
with the [TermOpen autocmd](https://neovim.io/doc/user/autocmd.html#TermOpen) or
so. The following is somewhat robust yet simple:

```lua
local auid = vim.api.nvim_create_augroup('vimterm_config', {})
vim.api.nvim_create_autocmd('TermOpen', {
  group = auid,
  callback = function(evt)
    local wo = vim.wo[vim.fn.bufwinid(evt.buf)]
    -- replace first %f in statusline with b:vimterm_name
    wo.statusline = wo.statusline:gsub('%%f', '%{get(b:, 'vimterm_name', 'term')}', 1)
  end
})
```


## Divergence

This plugin cannot completely mimic vim's `:term`. The main differences are
detailed here:
- `:term` is a hack and can't accept command modifiers
- `<C-w><C-c>` doesn't terminate the job
- `<C-w>.` accepts a count (eg, `<C-w>4.` inserts four literal `<C-w>` bytes)
- `<C-w><C-\>` accepts a count
- there is no 'termwinkey' in neovim, but it can be changed via the config


## Typical Workflow

Using `termwinkey = '<C-w>'` (the default - see
[Default Config](#default-config)):

| Cmd | Description |
| --- | ----------- |
| `:term` | open a split terminal \[1\]\[2\]  |
| `<C-w>p` | switch to the previous window \[3\] |
| `<C-w>:set winfixheight<CR>` | run the ex command `:set winfixheight` |
| `<C-w>10_` | set the terminal window's height to 10 lines |
| `<C-w>=` | make all windows the same size \[4\] |
| `<C-w>"+` | insert the system's PRIMARY clipboard |

- \[1\] other examples could also be `:vterm` to open in a vertical split or
  `:term python` to open a python repl
- \[2\] you'll already be in terminal mode, so just start typing
- \[3\] when you come back, **vimterm.nvim** will :startinsert will be run
  automatically to put you back into terminal mode
- \[4\] except we already set 'winfixheight' so the terminal window will remain
  only 10 lines tall

This is what it would look like otherwise:
- `:sp|term`
- `<C-\><C-n><C-w>p` (`i` when returning to the terminal window)
- `<C-\><C-o>:set winfixheight<CR>`
- `<C-\><C-o>:wincmd 10_<CR>`
- `<C-\><C-o>:wincmd =<CR>`
- `<C-\><c-o>"+p`


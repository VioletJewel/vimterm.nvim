# vimterm.nvim

Do you miss vim's `:terminal` but like neovim? This plugin fixes that! Have your
cake and eat it too.

- [Tl;dr](#tldr)
- [About](#about)
- [Split Terminals](#split-terminals)
  - [Term and Vterm Hacks](#term-and-vterm-hacks)
- [Terminal Prefix](#terminal-prefix)
  - [Ex Command](#ex-command)
  - [Register Paste](#register-paste)
  - [Tab Page Navigation](#tab-page-navigation)
  - [Wincmd](#wincmd)
  - [Literal Ctrl-w](#literal-ctrl-w)
  - [Literal Ctrl-bslash](#literal-ctrl-bslash)
- [Installation](#installation)
  - [Config](#config)

## Tl;dr

| Command | Type | Description |
| ------- | ---- | ----------- |
| `:Sterminal` | Ex Cmd | Open default 'shell' a split terminal |
| `:vterm python` | Ex Hack | Like `:vert Sterm python` |
| `<C-w>:echo 'hi'<CR>` | Term Cmd | Run one-time ex cmd (`:echo 'hi'`) |
| `<C-w>N`| Term Cmd | Go to normal mode |
| `<C-w>h` | Term Cmd | Move to left window (return to terminal mode later) |
| `<C-w>2"+` | Term Cmd | Insert PRIMARY clipboard register twice |
| `<C-w>gt` | Term Cmd | Go to next tab (return to terminal mode later) |
| `<C-w>=` | Term Cmd | Make all windows equal size |

## About

**vimterm.nvim** makes neovim's :terminal behave (almost 100%) like vim's
`:terminal`.

The only terminal commands in neovim are
[`t_CTRL-\_CTRL-N`](https://neovim.io/doc/user/intro.html#CTRL-%5C_CTRL-N) and
[`t_CTRL-\_CTRL-O`](https://neovim.io/doc/user/intro.html#CTRL-%5C_CTRL-O). This
is limiting, creates a verbose and annoying workflow, and is also divergent from
vim's methodology.

In vim, `t_CTRL-W` is a very powerful terminal command that enables many quick
actions. [You can investigate vim's `t_CTRL-W` maps further
here](https://vimhelp.org/terminal.txt.html#terminal-typing).

Vim also automatically starts terminal mode when a terminal is opened. Neovim
doesn't. This plugin fixes that, too.

This plugin also ensures that when the default
['shell'](https://neovim.io/doc/user/options.html#'shell') terminates
successfully (or error code 130, *"Process Closed By User"*), then the terminal
window is closed automatically. Otherwise, there was an error (or it was run
non-interactively); so, the window will stay open.

The terminal name (%f in
['statusline'](https://neovim.io/doc/user/options.html#'statusline')) in neovim
is also convoluted . This plugin sets `b:vimterm_name`. You can set 'statusline'
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

**Note:** While this plugin has been tested thoroughly, it is a little hacky. If
you have find a bug, please don't hesitate to open a ticket under **Issues**.


## Split Terminals

`:[{mods}] Sterminal [{cmd}]` opens a split terminal. This is how `:terminal`
behaves in vim.

`{mods}` are optional
[`:command-modifiers`](https://neovim.io/doc/user/map.html#%3Acommand-modifiers)
like `vertical`, `belowright`, `aboveleft`, `tab`, etc.

`{cmd}` is an optional command that is forwarded to
[`:terminal`](https://neovim.io/doc/user/various.html#%3Aterminal). See the help
for more info about `{cmd}`

Examples:
- `:Sterm` - opens the default 'shell' in a horizontally split terminal
- `:below vert Sterm` - opens the default 'shell' vertically split terminal on the
  right
- `:Sterm python` - opens a python repl in a horizontally split terminal
- `:tab Sterm` - opens a terminal in a new tab page

### Term and Vterm Hacks

`:term [{cmd}]` and `:vterm [{cmd}]` also automagically expand to `:Sterm` and
`:vert Sterm` (resp.).

Examples:
- `:term python` opens a python repl in a split terminal
- `:vterm` opens the default 'shell' in a vertically split terminal

**Note:** after you type ":term" and the space, `:term ` transforms instantly to
`:Sterm ` (because of using `:cabbrev`). This is a bit hacky. Therefore, you
cannot use `{mods}` like you can with `:Sterminal` (ie, `:vert term` won't
work). These hacks also have to be the first word in the cmdline (ie, neither
`: term` nor `:echo 'hi'|term` will work).


## Terminal Prefix

This plugin makes `<C-w>` be a "terminal prefix" (same as vim's
['termwinkey'](https://vimhelp.org/options.txt.html#%27termwinkey%27)). It can
be changed by setting `termwinkey` in the [Config](#config).

### Normal Mode

`<C-w>N` goes to normal mode. This works exacly like `<C-\><C-n>`, but it's
easier to type. You can also use `<C-w><C-n>`.

See vim's help on
[`t_CTRL-W_N`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_N) for more
info.

### Ex Command

`<C-w>:` temporarily opens the cmdline for one ex command. When the cmdline
exits, you're returned to terminal mode.

Examples:
- `<C-w>:echo 'hi'<CR>`

The vanilla alternative is `<C-\><C-o>:`.

See vim's help on
[`t_CTRL-W_:`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_%3A) for more
info.

### Register Paste

`<C-w>[{count}]"{reg}` inserts a register, `{reg}`, (optionally) `{count}` times.

Examples:
- `<C-w>""` inserts the unnamed register (`""`)
- `<C-w>"+` inserts the system's PRIMARY clipboard
- `<C-w>5"a` inserts the `"a` register 5 times.

The vanilla alternative (to paste `"a` register 5 times, eg) is
`<C-\><C-o>5"api`.

See vim's help on
[`t_CTRL-W_quote`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_quote) for
more info.

### Tab Page Navigation

`<C-w>gt` and `<C-w>gT` respectively navigate to the next and previous tab
pages. Terminal mode is automatically resumed upon navigating back to this
terminal window.

The vanilla alternative is `<C-\><C-n>gt` *and* when you return to this terminal
window, then you need to press `i`/`:startinsert` to get back into terminal
mode.

See vim's help on
[`t_CTRL-W_gt`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_gt) and
[`t_CTRL-W_gT`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_gT) for more
info.

### Wincmd

`<C-w>{wincmd}` performs window commands like `CTRL-W`
([`:wincmd`](https://neovim.io/doc/user/windows.html#%3Awincmd)) commands in the
terminal. Every normal mode window command (always prefixed with `<C-w>` in
normal mode) can be performed in terminal mode.

Examples:
- `<C-w>=` - resizes all windows to equal sizes (like
  [`CTRL-W_=`](https://neovim.io/doc/user/windows.html#CTRL-W_%3D))
- `<C-w>h` - moves one window left (like
  [`CTRL-W_h`](https://neovim.io/doc/user/windows.html#CTRL-W_h))
- `<C-w>H` - moves the current terminal window to the left half of the screen
  (like [`CTRL-W_H`](https://neovim.io/doc/user/windows.html#CTRL-W_H))
- etc: see [`:help windows.txt`](https://neovim.io/doc/user/windows.html) and
  search `/\*CTRL-W/` for all of the additional `<C-w>{wincmd}`possibilities.

The vanilla alternative is `<C-\><C-n><C-w>{wincmd}` *and* when you return to
this terminal window, then you need to press `i`/`:startinsert` to get back into
terminal mode.

See vim's help on
[`t_CTRL-W_:`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_CTRL-W) for more
info.

### Literal Ctrl-w

`<C-w>[{count}].` inserts a literal `<C-w>` `{count}` times into the shell. This
is slightly different from vim's
[`t_CTRL-W_.`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_%2E) because it
accepts a `{count}`.

Examples:
- `<C-w>.` - insert a literal `<C-w>`
- `<C-w>4.` - insert four literal `<C-w>`s

See vim's help on
[`t_CTRL-W_.`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_%2E) for more
info.

### Literal Ctrl-bslash

`<C-w>[{count}]<C-\>` inserts a literal `<C-\>` `{count}` times. This is slighly
different from vim's [`t_CTRL-W_CTRL-\` under `t_CTRL-W_N`
help](https://vimhelp.org/terminal.txt.html#t_CTRL-W_N) because it accepts a
`{count}`.

See vim's help on
[`t_CTRL-W_N`](https://vimhelp.org/terminal.txt.html#t_CTRL-W_N) for more
info.

## Installation

Ie, with [lazy.nvim](https://github.com/folke/lazy.nvim/):

```lua
{
  'VioletJewel/vimterm.nvim',
  config = { ... }
}
```

Alternatively, install it with a package manager
([pckr.nvim](https://github.com/lewis6991/pckr.nvim),
[paq.nvim](https://github.com/savq/paq-nvim),
[dep](https://github.com/chiyadev/dep),
[rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim), etc), ensure it's in
the ['runtimepath'](https://neovim.io/doc/user/options.html#'runtimepath'), or
ensure it's added as a pack package (see
[add-package](https://neovim.io/doc/user/usr_05.html#add-package)), and then do
something like the following once it is loaded:

```lua
local vtok, vimterm = pcall(require, 'vimterm')
if vtok then
  vimterm.setup{ ... }
end
```

**Note:** Replace `...` with some or all of the modified [Config](#config)
below (or leave it empty).

**Note:** You must call `vimterm.setup()` directly or indirectly (eg, with
lazy.nvim's `config = {}`; this can be empty or mod) to set up autocommands and
terminal maps.

### Config

Default config:

```lua
{
  termwinkey = '<C-w>',
  autoclose = true,
  autostartinsert = true,
  abbrevhack = true,
}
```

|||
|--|--|
| `termwinkey` | similar to vim's ['termwinkey'](https://vimhelp.org/options.txt.html#%27termwinkey%27) |
| `autoclose` | should the terminal close if the default shell exited successfully |
| `autostartinsert` | should the terminal automatically `:startinsert` after opening |
| `abbrevhack` | should **vimtern.vim** auto-expand `:term` and `:vterm` to `:Sterm` and `:vert Sterm` using cabbrev hack |

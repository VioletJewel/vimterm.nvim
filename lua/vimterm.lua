--- Make neovim's :terminal behave like vim's
--- @author Violet Jewel

-- Dear developer:
--   1. Do not switch :startinsert with nvim_feedkeys() or vice versa
--   2. Do not change nvim_feedkeys() modes
--   3. Do not use b:_vimterm_insert - use w:_vimterm_insert instead
-- Failure to adhere will likely result in the terminal freezing (esp. in tmux)

local M = {}

local auid = nil
local function au(evts, opts)
  vim.api.nvim_create_autocmd(evts, vim.tbl_extend('keep', opts, {group=auid}))
end

local d_termwinkey = '<C-w>'
local d_autoclose = true
local d_autostartinsert = true
local d_abbrevhack = true

local CB = string.char(28) -- <C-\>
local N = vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true) -- <C-\><C-n>
local CN = string.char(14) -- <C-n>

function M.setup(opts)
  if not opts then opts = {} end
  local termwinkey, autoclose, autostartinsert, abbrevhack
  termwinkey = opts.termwinkey == nil and d_termwinkey or opts.termwinkey
  autoclose = opts.autoclose == nil and d_autoclose or opts.autoclose
  autostartinsert = opts.autostartinsert == nil and d_autostartinsert or opts.autostartinsert
  abbrevhack = opts.abbrevhack == nil and d_abbrevhack or opts.abbrevhack

  auid = vim.api.nvim_create_augroup('vimterm', {})

  vim.keymap.set( 't', termwinkey, function()
    local wid = vim.api.nvim_get_current_win()
    local tcount = {}
    local ch = vim.fn.getcharstr()

    -- {count}
    if ch ~= '0' then
      while ch:match('^%d$') do -- count: /[1-9][0-9]*/
        tcount[#tcount+1] = ch
        ch = vim.fn.getcharstr()
      end
    end
    local scount = table.concat(tcount, '')

    -- Literal Ctrl-w
    if ch == '.' then
      return vim.api.nvim_feedkeys(string.rep(termwinkey, tonumber(scount) or 1), 'nt', true)
    elseif ch == CB then
      -- Literal Ctrl-bslash
      return vim.api.nvim_feedkeys(string.rep(CB, tonumber(scount) or 1), 'nt', false)
    elseif ch == 'g' then
      -- Tab Page Navigation: t_CTRL-W_gt, t_CTRL-W_gT
      ch = ch..vim.fn.getcharstr()
    elseif ch == 'N' or ch == CN then
      -- Normal Mode: CTRL-\_N or CTRL-\_CTRL-N
      return vim.api.nvim_feedkeys(N, 'n', false)
    elseif ch == '"' then
      -- Register Paste: t_CTRL-W_quote
      ch = vim.fn.escape(vim.fn.getcharstr())
      return vim.api.nvim_feedkeys('<C-\\>C-n>'..scount..'"'..ch..'pi', 'nt', true)
    end
    vim.w[wid]._vimterm_insert = true
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-bslash><c-n>'..scount..'<c-w>', true, false, true)..ch, '', false)
  end)

  -- :Sterminal for split terminal.
  vim.api.nvim_create_user_command('Sterminal',
    '<mods> split | terminal <args>', { nargs='*' })

  -- :STerminal for split terminal (for convenience/accidents).
  vim.api.nvim_create_user_command('STerminal',
    '<mods> split | terminal <args>', { nargs='*' })

  -- re-enter terminal mode when coming back if left with termwinkey
  au({'BufWinEnter','WinEnter','CmdlineLeave'}, {
    callback = function(evt)
      local win = vim.fn.bufwinid(evt.buf)
      if vim.o.buftype == 'terminal' and vim.w[win]._vimterm_insert then
        if vim.api.nvim_get_mode().mode ~= 't' then
          vim.cmd'startinsert'
          vim.w[win]._vimterm_insert = false
        end
      end
    end
  })

  au('TermOpen', {
    callback = function(evt)
      if vim.bo.buflisted then
        -- set b:vimterm_name (better than %f statusline flag).
        local vimterm_name = vim.api.nvim_buf_get_name(0):gsub('%S*:', '')
        if vimterm_name == vim.o.shell then
          vimterm_name = vimterm_name:gsub('.*/', '')
        end
        vim.b[evt.buf].vimterm_name = vimterm_name
        if autostartinsert then
          -- Auto :startinsert  when :terminal opened.
          --- @diagnostic disable-next-line
          if vim.fn.mode(1) ~= 't' then
            vim.cmd'startinsert'
          end
        end
      end
    end
  })

  if autoclose then
    -- Auto close :terminal only if default shell exits normally
    au('TermClose', {
      callback = function(evt)
        local code = vim.v.event.status
        if vim.o.shell == evt.file:gsub('%S*:', '') and code == 0 or code == 130 then
          vim.fn.feedkeys(' ', 'nt')
        end
      end
    })
  end

  if abbrevhack then
    -- (hack) expand :term to :Sterm.
    vim.keymap.set('ca', 'term',
      "getcmdtype() is ':' && getcmdline() =~# '^term' && getcmdpos() is 5 ? 'Sterm' : 'term'",
      { expr=true })

    -- (hack) expand :vterm to :vert Sterm.
    vim.keymap.set('ca', 'vterm',
      "getcmdtype() is ':' && getcmdline() =~# '^vterm' && getcmdpos() is 6 ? 'vert Sterm' : 'vterm'",
      { expr=true })
  end

end

return M


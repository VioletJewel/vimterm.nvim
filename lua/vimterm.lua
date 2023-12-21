--- Make neovim's :terminal behave like vim's
--- @author Violet Jewel

-- Dear developer:
--   1. Do not switch :startinsert with nvim_feedkeys() or vice versa
--   2. Do not change nvim_feedkeys() modes
--   3. Do not use b:_vimterm_insert - use w:_vimterm_insert instead
-- Failure to adhere will likely result in the terminal freezing (esp. in tmux)

local M = {}

local api = vim.api

local auid = nil
local function au(evts, opts)
  api.nvim_create_autocmd(evts, vim.tbl_extend('keep', opts, {group=auid}))
end

local d_termwinkey = '<C-w>'
local d_autoclose = true
local d_autostartinsert = true
local d_abbrevhack = true

local function keycode(s)
  return api.nvim_replace_termcodes(s, true, false, true)
end

local CB = keycode('<C-\\>')
local CBCn = keycode('<C-\\><C-n>')
local CBCo = keycode('<C-\\><C-o>')
local Cn = keycode('<C-n>')
local Cw = keycode('<C-w>')
local Ct = keycode('<C-t>')
local Cb = keycode('<C-b>')
local Ck = keycode('<C-k>')
local Cj = keycode('<C-j>')
local Ch = keycode('<C-h>')
local Cl = keycode('<C-l>')
local Up = keycode('<Up>')
local Down = keycode('<Down>')
local Left = keycode('<Left>')
local Right = keycode('<Right>')

function M.setup(opts)
  if not opts then opts = {} end
  local stermwinkey, termwinkey, autoclose, autostartinsert, abbrevhack
  stermwinkey = opts.termwinkey == nil and d_termwinkey or opts.termwinkey
  termwinkey = keycode(stermwinkey)
  autoclose = opts.autoclose == nil and d_autoclose or opts.autoclose
  autostartinsert = opts.autostartinsert == nil and d_autostartinsert or opts.autostartinsert
  abbrevhack = opts.abbrevhack == nil and d_abbrevhack or opts.abbrevhack

  auid = api.nvim_create_augroup('vimterm', {})

  vim.keymap.set( 't', stermwinkey, function()
    local wid = api.nvim_get_current_win()
    local tcount = {}
    local ch = vim.fn.getcharstr()

    if ch ~= '0' then -- {count}
      while ch:match('^%d$') do -- {count} /[1-9][0-9]*/
        tcount[#tcount+1] = ch
        ch = vim.fn.getcharstr()
      end
    end
    local scount = table.concat(tcount, '')

    if ch == '.' then -- Literal Ctrl-w
      return api.nvim_feedkeys(string.rep(termwinkey, tonumber(scount) or 1), 'nt', false)
    elseif ch == CB then -- Literal C-bslash
      return api.nvim_feedkeys(string.rep(CB, tonumber(scount) or 1), 'nt', false)
    elseif ch == 'g' then -- Tab Page Navigation: <C-w>gt, <C-w>gT
      ch = ch..vim.fn.getcharstr()
    elseif ch == 'N' or ch == Cn then -- Normal Mode: <C-w>N
      return api.nvim_feedkeys(CBCn, 'n', false)
    elseif ch == '"' then -- Register Paste: <C-w>"
      ch = vim.fn.escape(vim.fn.getcharstr())
      return api.nvim_feedkeys('<C-\\>C-n>'..scount..'"'..ch..'pi', 'nt', true)
    end

    local cbuf = api.nvim_get_current_buf()
    local nbuf = cbuf
    if ch == 'w' or ch == Cw then -- <C-w>w
      local ws = api.nvim_list_wins()
      local cwnr = api.nvim_win_get_number(api.nvim_get_current_win())
      local nwnum = scount == '' and (cwnr % #ws + 1) or math.min(#ws, tonumber(scount) or 1)
      nbuf = api.nvim_win_get_buf(ws[nwnum])
    elseif ch == 'W' then -- <C-w>W
      local ws = api.nvim_list_wins()
      local cwnr = api.nvim_win_get_number(api.nvim_get_current_win())
      local nwnum = scount == '' and ((cwnr - 1) % #ws + 1) or math.min(#ws, tonumber(scount) or 1)
      nbuf = api.nvim_win_get_buf(ws[nwnum])
    elseif ch == 't' or ch == Ct then -- <C-w>t
      nbuf = api.nvim_win_get_buf(api.nvim_list_wins()[1])
    elseif ch == 'b' or ch == Cb then -- <C-w>b
      nbuf = api.nvim_win_get_buf(api.nvim_list_wins()[1])
      local ws = api.nvim_list_wins()
      nbuf = api.nvim_win_get_buf(ws[#ws])
    elseif ch == 'gt' then -- <C-w>gt
      local ts = api.nvim_list_tabpages()
      if scount == '' then
        local ntnr = api.nvim_tabpage_get_number(api.nvim_get_current_tabpage()) % #ts + 1
        nbuf = api.nvim_win_get_buf(api.nvim_tabpage_get_win(ts[ntnr]))
      else
        local ntnr = tonumber(scount)
        if ntnr <= #ts then
          nbuf = api.nvim_win_get_buf(api.nvim_tabpage_get_win(ts[ntnr]))
        end
      end
    elseif ch == 'gT' then -- <C-w>gT (note: different than gt: {count} = cyclical)
      local ts = api.nvim_list_tabpages()
      local ctnr = api.nvim_tabpage_get_number(api.nvim_get_current_tabpage())
      local ntnr = ((ctnr - (tonumber(scount) or 1)) % #ts + 1)
      nbuf = api.nvim_win_get_buf(api.nvim_tabpage_get_win(ts[ntnr]))
    elseif ch == 'k' or ch == Ck or ch == Up then -- <C-w>k
      nbuf = vim.fn.winbufnr(vim.fn.winnr'k')
    elseif ch == 'j' or ch == Cj or ch == Down then -- <C-w>j
      nbuf = vim.fn.winbufnr(vim.fn.winnr'j')
    elseif ch == 'h' or ch == Ch or ch == Left then -- <C-w>h
      nbuf = vim.fn.winbufnr(vim.fn.winnr'h')
    elseif ch == 'l' or ch == Cl or ch == Right then -- <C-w>l
      nbuf = vim.fn.winbufnr(vim.fn.winnr'l')
    end

    vim.w[wid]._vimterm_insert = cbuf ~= nbuf
    local p = vim.bo[nbuf].buftype == 'terminal' and CBCo or CBCn
    api.nvim_feedkeys(p..scount..Cw..ch, 'n', false)
  end)

  -- :Sterminal for split terminal.
  api.nvim_create_user_command('Sterminal', '<mods> split | terminal <args>', { nargs='*' })

  -- :STerminal for split terminal (for convenience/accidents).
  api.nvim_create_user_command('STerminal', '<mods> split | terminal <args>', { nargs='*' })

  -- re-enter terminal mode when coming back if left with termwinkey
  au({'BufWinEnter','WinEnter','CmdlineLeave'}, {
    callback = function(evt)
      local win = vim.fn.bufwinid(evt.buf)
      if vim.o.buftype == 'terminal' and vim.w[win]._vimterm_insert then
        if api.nvim_get_mode().mode ~= 't' then
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
        local vimterm_name = api.nvim_buf_get_name(0):gsub('%S*:', '')
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


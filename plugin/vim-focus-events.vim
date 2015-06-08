" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1
" @license MIT, (c) amerlyq, 2015
" @brief Integration with term to receive focus events in vim. Auto-copy widget.

if has('gui_running') || &cp || version < 700 ||
      \ (exists('g:did_term_focus') && g:did_term_focus) | finish | endif
let g:did_term_focus = 1

"" Preserve previous cursor state
" let s:old_SI=&t_SI | let s:old_EI=&t_EI
let s:save_cpo = &cpo
set cpo&vim

"=============================================================================
" OPTIONS

" Must be defined separately from default_settings.
let g:term_auto_configure = 1

" NOTE: check codes in terminal by (silent !echo -ne "...")
" Defaults for iTerm2, " Up to <F37>
" Use modern xterm codes (or create your own: ^[[UlFocusIn, ^[[UlFocusOut)

let s:default_settings = {
    \ 'modes_activate': 1,
    \ 'sync_clipboard': 1,
    \ 'sync_filestate': 0,
    \ 'key_in':  '<F24>',
    \ 'key_out': '<F25>',
    \ 'event_in':  "\e[I",
    \ 'event_out': "\e[O",
    \ 'cursor_normal': '',
    \ 'cursor_insert': '',
    \ 'color_primary': 'white',
    \ 'color_secondary': 'cyan',
    \ 'focus_on':  "\e[?1004h",
    \ 'focus_off': "\e[?1004l",
    \ 'screen_save':    "\e[?1049h",
    \ 'screen_restore': "\e[?1049l",
    \ 'clipreg_system': '+',
    \ 'clipreg_noname': '"',
    \ 'clipreg_backup': 'p',
    \ }

function! s:safe_define(...)
  let opts = a:0>1 ? a:1 : keys(a:1)
  let vals = a:0>1 ? a:2 : values(a:1)
  for i in range(min([len(opts), len(vals)]))  " a:{i}
    let op = 'g:term_' . opts[i]
    if !exists(op)
      exec 'let '. op .'="'. vals[i] .'"'
    endif
  endfor
endfunction

"=============================================================================
" AUTO-CHOOSE

function! s:term_events_choose()
  if &term =~ "^xterm\\|rxvt"
    let events = ["\e]777;focus;on\x7", "\e]777;focus;off\x7"]
  elseif exists('$ITERM_PROFILE')
    let events = ["\e[?1004h", "\e[?1004l"]
  else
    let events = ['', '']
    echom "Seems like your $TERM has no support for mouse focuse. Disabled."
    echom "If you don't agree, disable auto_choose and set escape codes by yourself."
  endif

  call s:safe_define(['focus_on', 'focus_off'], events)
endfunction


function! s:term_shape_choose()
  if &term =~ "^xterm\\|rxvt"
    " [1,2] -> [blinking,solid] block
    " [3,4] -> [blinking,solid] underscore
    " [5,6] -> [blinking,solid] vbar (only in xterm > 282), not in urxvt?
    let shapes = ["\e[2 q", "\e[4 q"]
  elseif exists('$ITERM_PROFILE')
    let shapes = ["\e]50;CursorShape=0\x7", "\e]50;CursorShape=1\x7"]
  else
    let shapes = ['', '']
    echom "Can't autodetect shape escape codes for this $TERM"
  endif

  call s:safe_define(['cursor_normal', 'cursor_insert'], shapes)
endfunction


function! s:term_color_choose(idx)
  if &term =~ "^xterm\\|rxvt"
    let colors = [ "\e]12;". g:term_color_primary ."\x7",
                 \ "\e]12;". g:term_color_secondary ."\x7" ]
  else
    "" ALT: ["\e]12;white\x9c", "\e]12;orange\x9c"]
    " use default \003]12;gray\007 for gnome-terminal
    let colors = ['', '']
    echom "Can't autodetect color escape codes for this $TERM"
  endif
  return l:colors[a:idx]
endfunction


"=============================================================================
" INTEGRATION

function! s:term_modes_enable(state)
  let g:term_modes_activate = a:state
  if g:term_modes_activate

    "" FIX: add two color groups based on language, not permanent. See xkb.
    let clr = s:term_color_choose(0)

    " Install insert mode autohooks -- on enter/leave
    let &t_SI = g:term_cursor_insert . l:clr
    let &t_EI = g:term_cursor_normal . l:clr

    let on_init = &t_EI . g:term_focus_on
    let on_exit = g:term_focus_off

    " WARNING: must be outside this 'if', as it will not work in tmux
    " on_disable!
    if exists('$TMUX')
      " Disable bkgd color erase to adequate bkgd color
      set t_ut=
      let on_init = s:tmux_wrap(on_init)
      let on_exit = s:tmux_wrap(on_exit)
    endif

    " Install focus autohooks -- on startup/shutdown
    let &t_ti = on_init . g:term_screen_save
    let &t_te = on_exit . g:term_screen_restore

    " CHECK: Is it necessary to be able toggle dynamically?
    " exec 'silent !echo -ne "'. &t_EI .g:term_focus_on .g:term_screen_save .'"'
  else
    let &t_ti = ''
    let &t_te = ''

    " CHECK: Is it necessary to be able toggle dynamically?
    " exec 'silent !echo -ne "'. g:term_focus_off .g:term_screen_restore .'"'
  endif
  " ALT:
  " augroup term_focus
  "   autocmd!
  "   if a:state
  "     au VimEnter    * call s:term_cso('on')
  "     au VimLeavePre * call s:term_cso('off')
  "   endif
  " augroup END
endfunction


function s:do_in_cmd(cmd)
  let cmd = getcmdline()
  let pos = getcmdpos()
  exec a:cmd
  call setcmdpos(pos)
  return cmd
endfunction


function! s:map_all_modes(keys, mid, cmds)
  let kmd = ['n', 'o', 'x', 'i', 'c']
  let beg = 'noremap <silent> <unique> '
  let prf = ['', '<Esc>', '<Esc>', '<C-o>', '<C-\>e<SID>do_in_cmd("']
  for m in range(len(kmd))
    if 'c'==kmd[m] | let mid=a:mid | let end=' %")<CR>'
    else | let mid=':'.a:mid | let end=' %<CR>' | endif
    if 'x'==kmd[m] | let end.='gv'  | endif
    for i in range(len(a:keys))
      exec kmd[m].beg. a:keys[i].' '.prf[m].mid. a:cmds[i] .end
    endfor
  endfor
endfunction


function! s:term_init()

  if g:term_auto_configure
    call s:term_events_choose()
    call s:term_shape_choose()

    "" FIX: must be dynamic and check current lang before each mode
    " or lang switching.
    " call s:term_lang_choose() "primary/secondary
  endif

  " Define all default options which left undefined till now.
  call s:safe_define(s:default_settings)

  " Map all
  let keys  = [g:term_key_in, g:term_key_out]
  let codes = [g:term_event_in, g:term_event_out]
  for i in range(len(keys)) | exec 'set '. keys[i] .'='. codes[i] | endfor
  call s:map_all_modes(keys, 'silent doau ', ['FocusGained', 'FocusLost'])

  call s:term_modes_enable(g:term_modes_activate)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

"=============================================================================
" MAPPINGS

call s:term_init()

" MAYBE unnecessary?
" autocmd! VimEnter * call s:term_modes_enable(1)


" BUG: has no effect on restoring color after exit.
"" There are sequence to change color, but not the one to restore to default
" SEE Maybe save/restore the screen -- works for cursor? -- seems NO.
augroup TermFocusCursor
  autocmd!
  "" Restore cursor color and shape upon exit
  autocmd VimLeave * let &t_SI = s:old_SI | let &t_EI = s:old_EI
augroup END


" | redraw!
command! -bar -bang -nargs=0 TermFocusEnable call s:term_modes_enable(<bang>1)
command! -bar -bang -nargs=0 TermFocusToggle call s:term_modes_enable(!g:term_modes_activate)

nnoremap <unique> <Leader>tF :TermFocusToggle<CR>

"=============================================================================
" WIDGETS

if g:term_sync_clipboard
  function! s:CopyReg(src, dst, ...)
    if a:0 > 0 | call setreg(a:1, getreg(a:dst, 1), getregtype(a:dst)) | endif
    call setreg(a:dst, getreg(a:src, 1), getregtype(a:src))
  endfunction

  "" ALT: If vim compiled w/o clipboard or launched by ssh:
  " command -range Cz silent <line1>,<line2>write !xsel -ib
  " cabbrev cv Cv  " To be able do simple ':cv' to copy text
  " write !xsel -ib
  " read !xsel -ob

  "" ALT: Autosync regs @" and @+
  " set clipboard^=unnamedplus
endif


augroup TermFocusEvent
  autocmd!
  "" Testing
  " au FocusGained * set number
  " au FocusLost   * set nonumber

  "" NOTE: FocusGained in next vim is triggered BEFORE FocusLost in previous
  ""       Fixed by sleep 10 mS inside urxvt-focus
  if g:term_sync_clipboard
    au FocusGained * call s:CopyReg(g:term_clipreg_system,
          \ g:term_clipreg_noname, g:term_clipreg_backup)
    au FocusLost   * call s:CopyReg(g:term_clipreg_noname,
          \ g:term_clipreg_system)
  endif

  "" Reload all changed, save all unchanged
  if g:term_sync_filestate
    au FocusGained * bufdo checktime
    au FocusLost   * wa!
  endif
augroup END

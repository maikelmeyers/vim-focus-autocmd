" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1:tw=76
" @license MIT, (c) amerlyq, 2015
" @brief Integration with term to receive focus events in vim.
"        Auto-copy widget.

if &cp || version < 700 || (exists('g:afoc_loaded') && g:afoc_loaded) | finish
      \ | else | let g:afoc_loaded = 1 | endif
"" Preserve previous cursor state
let s:old_SI=&t_SI | let s:old_EI=&t_EI
let s:save_cpo = &cpo
set cpo&vim

"===========================================================================
" OPTIONS

" Must be defined separately from default_settings.
let g:afoc_auto_configure = 1

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
    let op = 'g:afoc_' . opts[i]
    if !exists(op)
      exec 'let '. op .'="'. vals[i] .'"'
    endif
  endfor
endfunction

"===========================================================================
" AUTO-CHOOSE

function! s:afoc_events_choose()
  if &term =~ "^rxvt"
    let events = ["\e]777;focus;on\x7", "\e]777;focus;off\x7"]
  " NOTE: screen supports
  elseif &term =~ "^xterm\\|screen" || exists('$ITERM_PROFILE')
    let events = ["\e[?1004h", "\e[?1004l"]
  else
    let events = ['', '']
    echom "Seems like your $TERM has no support for mouse focuse. Disabled."
    echom "If curious, disable 'auto_choose' and set escape codes manually."
  endif

  call s:safe_define(['focus_on', 'focus_off'], events)
endfunction


function! s:afoc_shape_choose()
  if &term =~ "^rxvt\\|screen"
    " [1,2] -> [blinking,solid] block
    " [3,4] -> [blinking,solid] underscore
    " [5,6] -> [blinking,solid] vbar/I-beam (only in xterm > 282),
    "     urxvt got I-beam only in v9.21 2014-12-31, build from recent git.
    let shapes = ["\e[2 q", "\e[4 q"]
    "" DISABLED: to reduce startup time, and it will not work through ssh
    " let l:uver = substitute(split(system('urxvt -help 2>&1'), '\n')[0],
    "       \ '.*v\([0-9.]\+\).*', '\1', '')
    " let shapes = ["\e[2 q", (9.21 <= l:uver ? "\e[6 q" : "\e[4 q")]
  elseif &term =~ "^xterm"
    let shapes = ["\e[2 q", "\e[6 q"]
  elseif &term =~ "^Konsole" || exists('$ITERM_PROFILE')
    let shapes = ["\e]50;CursorShape=0\x7", "\e]50;CursorShape=1\x7"]
  else
    let shapes = ['', '']
    echom "Shape escape codes: can't autodetect for $TERM=" . $TERM
  endif

  call s:safe_define(['cursor_normal', 'cursor_insert'], shapes)
endfunction


function! s:afoc_color_choose(idx)
  if &term =~ "^xterm\\|screen\\|rxvt"
    let colors = [ "\e]12;". g:afoc_color_primary ."\x7",
                 \ "\e]12;". g:afoc_color_secondary ."\x7" ]
  else
    "" ALT: ["\e]12;white\x9c", "\e]12;orange\x9c"]
    " use default \003]12;gray\007 for gnome-terminal
    let colors = ['', '']
    echom "Color escape codes: can't autodetect for $TERM=" . $TERM
  endif
  return l:colors[a:idx]
endfunction


"===========================================================================
" INTEGRATION

"" WARNING: For focus-events to work in tmux, you need to set this option
" inside your tmux.conf:   set -g focus-events on

" WARNING: must be outside this 'if' in s:afoc_modes_enable, as it will not
" work in tmux on_disable!
if exists('$TMUX')
  " Disable bkgd color erase and don't truncate highlighting
  " So highlighted line does go all the way across screen
  set t_ut=
  function! s:tmux_wrap(s)
    return "\ePtmux;". substitute(a:s, "\e\\|\<Esc>", "\e\e", 'g') ."\e\\"
  endfunction
else
  function! s:tmux_wrap(s)
    return a:s
  endfunction
endif


function! s:afoc_modes_enable(state)
  let g:afoc_modes_activate = a:state
  if g:afoc_modes_activate

    "" FIX: add two color groups based on language, not permanent. See xkb.
    let color = s:afoc_color_choose(0)

    " Install insert mode autohooks -- on enter/leave
    let &t_SI = s:tmux_wrap(g:afoc_cursor_insert . l:color)
    let &t_EI = s:tmux_wrap(g:afoc_cursor_normal . l:color)

    let on_init = &t_EI . s:tmux_wrap(g:afoc_focus_on)
    let on_exit = s:tmux_wrap(g:afoc_focus_off)

    " Install focus autohooks -- on startup/shutdown
    let &t_ti = on_init . g:afoc_screen_save
    let &t_te = on_exit . g:afoc_screen_restore

    " CHECK: Is it necessary to be able toggle dynamically?
    " exec 'silent !echo -ne "'. &t_EI .g:afoc_focus_on .g:afoc_screen_save .'"'
  else
    let &t_ti = ''
    let &t_te = ''

    " CHECK: Is it necessary to be able toggle dynamically?
    " exec 'silent !echo -ne "'. g:afoc_focus_off .g:afoc_screen_restore .'"'
  endif
  " ALT:
  " augroup afoc_focus
  "   autocmd!
  "   if a:state
  "     au VimEnter    * call s:afoc_cso('on')
  "     au VimLeavePre * call s:afoc_cso('off')
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


function! s:afoc_init()
  if g:afoc_auto_configure
    call s:afoc_events_choose()
    call s:afoc_shape_choose()

    "" FIX: must be dynamic and check current lang before each mode
    " or lang switching.
    " call s:afoc_lang_choose() "primary/secondary
  endif

  " Define all default options which left undefined till now.
  call s:safe_define(s:default_settings)

  " Map all
  let keys  = [g:afoc_key_in, g:afoc_key_out]
  let codes = [g:afoc_event_in, g:afoc_event_out]
  for i in range(len(keys)) | exec 'set '. keys[i] .'='. codes[i] | endfor
  call s:map_all_modes(keys, 'silent doau ', ['FocusGained', 'FocusLost'])

  call s:afoc_modes_enable(g:afoc_modes_activate)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

"===========================================================================
" MAPPINGS

if !has('gui_running')
  call s:afoc_init()

  " MAYBE unnecessary?
  " autocmd! VimEnter * call s:afoc_modes_enable(1)

  " BUG: has no effect on restoring color after exit.
  "" There are sequence to change color, but not the one to restore to default
  " SEE Maybe save/restore the screen -- works for cursor? -- seems NO.
  augroup AuFocusCursor
    autocmd!
    "" Restore cursor color and shape upon exit
    autocmd VimLeave * let &t_SI = s:old_SI | let &t_EI = s:old_EI
  augroup END

  " | redraw!
  command! -bar -bang -nargs=0 AuFocusEnable
        \ call s:afoc_modes_enable(<bang>1)
  command! -bar -bang -nargs=0 AuFocusToggle
        \ call s:afoc_modes_enable(!g:afoc_modes_activate)
  nnoremap <unique> <Leader>tF :AuFocusToggle<CR>
endif

"=============================================================================
" WIDGETS
" NOTE: widgets work in gvim even w/o previous integration with terminal.

if g:afoc_sync_clipboard
  function! s:CopyReg(src, dst, ...)
    if a:0 > 0 | call setreg(a:1, getreg(a:dst, 1), getregtype(a:dst)) | endif
    call setreg(a:dst, getreg(a:src, 1), getregtype(a:src))
  endfunction

  command! -bar -bang -nargs=0 AuFocusCopyIn call s:CopyReg(
        \ g:afoc_clipreg_system, g:afoc_clipreg_noname, g:afoc_clipreg_backup)
  command! -bar -bang -nargs=0 AuFocusCopyOut call s:CopyReg(
        \ g:afoc_clipreg_noname, g:afoc_clipreg_system)
endif

"" ALT: If vim compiled w/o clipboard or launched by ssh:
" command -range Cz silent <line1>,<line2>write !xsel -ib
" cabbrev cv Cv  " To be able do simple ':cv' to copy text
" write !xsel -ib
" read !xsel -ob



augroup AuFocusEvent
  autocmd!
  "" Testing
  " au FocusGained * set number
  " au FocusLost   * set nonumber

  if g:afoc_sync_clipboard
    au FocusGained * AuFocusCopyIn
    au FocusLost   * AuFocusCopyOut
    au VimEnter    * AuFocusCopyIn
    au VimLeavePre * AuFocusCopyOut
  endif

  "" Reload all changed, save all unchanged
  if g:afoc_sync_filestate
    au FocusGained * bufdo checktime
    au FocusLost   * wa!
  endif
augroup END

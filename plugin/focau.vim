" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1:tw=76
" @license MIT, (c) amerlyq, 2015
" @brief Integration with term to receive focus events in vim.
"        + Auto-copy widget.

if &cp || version < 700 || exists('g:loaded_focau') | finish | endif
let s:save_cpo = &cpo
set cpo&vim

" Must be defined separately from default_settings.
let g:focau_auto_configure = 1

" NOTE: check codes in terminal by (silent !echo -ne "...")
" Defaults for iTerm2, " Up to <F37>
" Use modern xterm codes (or create your own: ^[[UlFocusIn, ^[[UlFocusOut)

" You can setup options in .vimrc w/o '_defaults.' part (Like: g:focau_events=)
let g:focau_defaults = {'active': 1}
let g:focau_defaults.events   = {'<F25>': "\e[I", '<F26>': "\e[O"}
let g:focau_defaults.focuses  = ["\e[?1004h", "\e[?1004l"]
let g:focau_defaults.screens  = ["\e[?1049h", "\e[?1049l"]
let g:focau_defaults.cursors  = ['', '', '']
let g:focau_defaults.colors   = ['white', 'cyan']
let g:focau_defaults.widgets  = ['clipboard', 'buffers', 'number']
let g:focau_defaults.clipregs = ['+"p', '"+']

" NOTE: widgets work in gvim even w/o previous integration with terminal.
if !has('gui_running')
  call focau#init#main(get(g:, 'focau_auto_configure', 0))
  call focau#events#enable(g:focau_active)
  " Load specified widgets
  for wdg in g:focau_widgets | call focau#widget#{wdg}() | endfor

  command! -bar -bang -nargs=0 FocusAutocmdEnable
        \ call focau#events#enable(<bang>1)
  command! -bar -bang -nargs=0 FocusAutocmdToggle
        \ call focau#events#enable(!g:focau_active)
  " MAYBE unnecessary?
  " au! focau VimEnter * FocusAutocmdEnable
endif

let g:loaded_focau = 1
let &cpo = s:save_cpo
unlet s:save_cpo

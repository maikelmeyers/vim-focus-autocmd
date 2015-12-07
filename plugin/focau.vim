" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1:tw=76
" @license MIT, (c) amerlyq, 2015
" @brief Integration with term to receive focus events in vim.
"        + Auto-copy widget.

if &cp || version < 700 || exists('g:loaded_focau') | finish | endif
let s:save_cpo = &cpo
set cpo&vim

" NOTE: check codes in terminal by (silent !echo -ne "...")
" Codes are default for iTerm2. Keys for events -- use up to <F37>
" Use modern xterm codes (or create your own: ^[[UlFocusIn, ^[[UlFocusOut)
let g:focau = extend({
  \ 'auto': 1,
  \ 'active': 1,
  \ 'events' : {'<F25>': "\e[I", '<F26>': "\e[O"},
  \ 'focuses': ["\e[?1004h", "\e[?1004l"],
  \ 'screens': ["\e[?1049h", "\e[?1049l"],
  \ 'cursors': ['', '', ''],
  \ 'colors' : ['white', 'cyan'],
  \ 'widgets': [],
  \ 'clipregs':['+"p', '"+'],
  \}, get(g:, 'focau', {}))
" widgets: ['clipboard', 'buffers', 'number']


" NOTE: gvim and nvim>v0.1.1 (for XTerm, Konsole) works as is.
if !has('gui_running') && (!has('nvim') || $TERM =~ '^rxvt')
  call focau#init#main()

  command! -bar -bang -nargs=0 FocusAutocmdEnable
        \ call focau#events#enable(<bang>1)
  command! -bar -bang -nargs=0 FocusAutocmdToggle
        \ call focau#events#enable(!g:focau.active)
endif

" Load specified widgets -- both for TUI ang GUI
for wdg in g:focau.widgets
  call focau#widget#{wdg}()
endfor

let g:loaded_focau = 1
let &cpo = s:save_cpo
unlet s:save_cpo

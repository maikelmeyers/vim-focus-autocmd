exe "fun! s:F0()\nsil! doau FocusGained|return''\nendf"
exe "fun! s:F1()\nsil! doau FocusLost  |return''\nendf"

function! s:map_triggers(keys)
  for m in split('noxic', '\zs') | for i in range(2)
    exe m.'noremap <silent><unique><expr> '.a:keys[i].' <SID>F'.i.'()'
  endfor | endfor
endfunction


function! s:safe_define(opts)
  for [k, v] in items(a:opts)
    if !exists('g:focau_'.k) | let g:focau_{k}=v | endif
    unlet k v
  endfor
endfunction


function! focau#init#main(auto_choose)
  call focau#cursor#auto_restore()
  if a:auto_choose
    call s:safe_define({'focuses': focau#events#auto_choose()})
    call s:safe_define({'cursors': focau#cursor#auto_shape()})
    "" FIX: must be dynamic and check curr lang before each mode/lang-switch
    " call s:focau_lang_choose() "primary/secondary
  endif
  " Define all default options which left undefined till now.
  call s:safe_define(g:focau_options)
  " Wrap choosen keys in event triggers
  for [key, code] in items(g:focau_events) | exe 'set '.key.'='.code | endfor
  call s:map_triggers(keys(g:focau_events))
endfunction

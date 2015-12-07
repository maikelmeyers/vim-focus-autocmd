" WARNING: seems like we can't use <expr> maps, because we need side-effects
" ALT: {s: <C-g>...<C-g>, o: <Esc>, i: <C-o>, c: <C-\>e}
function! s:map_triggers(keys)
  for [a, i] in items({'FocusGained': 0, 'FocusLost': 1})
    exe "fun! s:F".i."()\nsil! doau ".a."|return''\nendf"
    for [ms, prf] in items({'nv': '@=', 'o': ':call ', 'ic': '<C-r>='})
      for m in split(ms, '\zs')
        exe m.'noremap <silent><unique> '.a:keys[i].' '.prf.'<SID>F'.i.'()<CR>'
  endfor | endfor | endfor
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
  call s:safe_define(g:focau_defaults)
  " Wrap choosen keys in event triggers
  for [key, code] in items(g:focau_events) | exe 'set '.key.'='.code | endfor
  call s:map_triggers(keys(g:focau_events))
endfunction

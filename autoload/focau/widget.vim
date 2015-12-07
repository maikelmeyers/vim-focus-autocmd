" Testing
function! focau#widget#number()
  augroup focau
    au FocusGained * set number
    au FocusLost   * set nonumber
  augroup END
endfunction


" Sync clipboard with unnamed register
function! focau#widget#clipboard()
  "" ALT: If vim compiled w/o clipboard or launched by ssh:
  " command -range Cz silent <line1>,<line2>write !xsel -ib
  " cabbrev cv Cv  " To be able do simple ':cv' to copy text
  " write !xsel -ib
  " read !xsel -ob

  function! s:CopyReg(src, dst, ...)
    if a:0 > 0 | call setreg(a:1, getreg(a:dst, 1), getregtype(a:dst)) | endif
    call setreg(a:dst, getreg(a:src, 1), getregtype(a:src))
  endfunction

  function! s:CopyClosure(au, idx)
    exec printf("au focau %s * call s:CopyReg(%s)", a:au, join(map(split(
          \ g:focau.clipregs[a:idx], '\zs'), '"''".v:val."''"'), ','))
  endfunction

  call s:CopyClosure('FocusGained', 0)
  call s:CopyClosure('FocusLost',   1)
endfunction


" Reload all changed, save all unchanged
function! focau#widget#buffers()
  augroup focau
    au FocusGained * bufdo checktime
    au FocusLost   * bufdo update!
  augroup END
endfunction

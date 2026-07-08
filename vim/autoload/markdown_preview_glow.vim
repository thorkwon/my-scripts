function! markdown_preview_glow#open() abort
  if !executable('glow')
    echoerr 'markdown-preview-glow: glow executable was not found'
    return
  endif

  if !exists('*term_start')
    echoerr 'markdown-preview-glow: this Vim does not support terminal buffers'
    return
  endif

  if expand('%:p') ==# ''
    echoerr 'markdown-preview-glow: save this markdown buffer before previewing'
    return
  endif

  let l:source_bufnr = bufnr('%')
  let l:source_file = expand('%:p')

  enew
  silent file [Glow\ Preview]
  call term_start(['glow', l:source_file], {
        \ 'curwin': v:true,
        \ 'term_finish': 'open',
        \ })
  let b:markdown_preview_glow_source_bufnr = l:source_bufnr
  setlocal bufhidden=wipe
  setlocal nobuflisted

  nnoremap <buffer> q :call markdown_preview_glow#close()<CR>
  tnoremap <buffer> q <C-W>N:call markdown_preview_glow#close()<CR>
endfunction

function! markdown_preview_glow#close() abort
  let l:preview_bufnr = bufnr('%')
  let l:source_bufnr = get(b:, 'markdown_preview_glow_source_bufnr', -1)

  if l:source_bufnr > 0 && bufexists(l:source_bufnr)
    execute 'buffer!' l:source_bufnr
    if bufexists(l:preview_bufnr)
      execute 'bwipeout!' l:preview_bufnr
    endif
  else
    bwipeout!
  endif
endfunction

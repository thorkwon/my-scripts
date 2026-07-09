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
  " Remember where the cursor was so we can restore it in the preview.
  let l:source_line = line('.')
  let l:source_last = line('$')

  enew
  silent file [Glow\ Preview]
  let l:preview_width = max([20, winwidth(0) - &numberwidth - 3])
  call term_start(['glow', '-w', string(l:preview_width), l:source_file], {
        \ 'curwin': v:true,
        \ 'term_finish': 'open',
        \ })
  let l:preview_bufnr = bufnr('%')
  setlocal number norelativenumber nowrap foldcolumn=0
  if exists('+signcolumn')
    setlocal signcolumn=no
  endif
  let b:markdown_preview_glow_source_bufnr = l:source_bufnr
  let b:markdown_preview_glow_source_line = l:source_line
  let b:markdown_preview_glow_source_last = l:source_last
  setlocal bufhidden=wipe
  setlocal nobuflisted

  nnoremap <buffer> q :call markdown_preview_glow#close()<CR>
  tnoremap <buffer> q <C-W>N:call markdown_preview_glow#close()<CR>

  " glow scrolls the terminal to the bottom while rendering; once the job
  " finishes, move the cursor back to the line the user was reading.
  call timer_start(50, function('s:restore_cursor', [l:preview_bufnr, 0]))
endfunction

function! s:restore_cursor(preview_bufnr, tries, timer) abort
  if !bufexists(a:preview_bufnr)
    return
  endif

  " Wait until glow has exited before repositioning the cursor.
  if term_getstatus(a:preview_bufnr) =~# 'running'
    if a:tries < 40
      call timer_start(50, function('s:restore_cursor', [a:preview_bufnr, a:tries + 1]))
    endif
    return
  endif

  " The process exiting is not the same as the terminal finishing its screen
  " updates: glow's output may still be draining and would scroll the view
  " back to the bottom after we move the cursor. Flush all pending terminal
  " output first so our reposition sticks.
  if exists('*term_wait')
    call term_wait(a:preview_bufnr, 30)
  endif

  call s:apply_position(a:preview_bufnr)

  " Some builds emit one more redraw right after the job ends, which scrolls
  " the view back to the bottom. Re-apply once more shortly after to win that
  " race regardless of the exact timing on a given machine.
  call timer_start(120, function('s:apply_position', [a:preview_bufnr]))
endfunction

function! s:apply_position(preview_bufnr, ...) abort
  if !bufexists(a:preview_bufnr)
    return
  endif

  if exists('*term_wait')
    call term_wait(a:preview_bufnr, 10)
  endif

  let l:winnr = bufwinnr(a:preview_bufnr)
  if l:winnr == -1
    return
  endif

  let l:src_line = getbufvar(a:preview_bufnr, 'markdown_preview_glow_source_line', 0)
  let l:src_last = getbufvar(a:preview_bufnr, 'markdown_preview_glow_source_last', 0)
  if l:src_line <= 0 || l:src_last <= 0
    return
  endif

  " Switch into the preview window and reposition there. Using wincmd/line()
  " without a winid keeps this working on older Vim builds that lack
  " win_execute() and the line({expr}, {winid}) argument.
  let l:cur_winnr = winnr()
  execute l:winnr . 'wincmd w'

  " glow reflows and styles the source, so line numbers do not match 1:1.
  " Map the source position proportionally onto the rendered output.
  let l:preview_last = line('$')
  let l:target = float2nr(round(l:src_line * 1.0 / l:src_last * l:preview_last))
  if l:target < 1
    let l:target = 1
  elseif l:target > l:preview_last
    let l:target = l:preview_last
  endif

  call cursor(l:target, 1)
  normal! zz

  " Restore focus to the window that was active before repositioning.
  if l:cur_winnr != l:winnr && l:cur_winnr <= winnr('$')
    execute l:cur_winnr . 'wincmd w'
  endif
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

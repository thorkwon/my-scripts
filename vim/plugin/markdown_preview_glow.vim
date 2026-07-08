" Markdown preview rendered by glow inside Vim.
if exists('g:loaded_markdown_preview_glow')
  finish
endif
let g:loaded_markdown_preview_glow = 1

augroup markdown_preview_glow
  autocmd!
  autocmd FileType markdown nnoremap <buffer> mp :call markdown_preview_glow#open()<CR>
augroup END

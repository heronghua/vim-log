" 注册 :S 命令
if !exists(':S')
  command! -nargs=1 S call loghigh#Search(<q-args>)
endif

" 在日志文件中设置按键映射
augroup LogHighKeymaps
  autocmd!
  autocmd FileType log call s:setup_log_keymaps()
augroup END

" 设置日志文件的按键映射
function! s:setup_log_keymaps() abort
  " Shift+上箭头 - 增加 quickfix 高度
  if !hasmapto('<Plug>LogHighIncreaseQF', 'n')
    nmap <silent> <S-Up> <Plug>LogHighIncreaseQF
  endif
  nnoremap <silent> <Plug>LogHighIncreaseQF :call loghigh#IncreaseQFHeight()<CR>
  
  " Shift+下箭头 - 减少 quickfix 高度
  if !hasmapto('<Plug>LogHighDecreaseQF', 'n')
    nmap <silent> <S-Down> <Plug>LogHighDecreaseQF
  endif
  nnoremap <silent> <Plug>LogHighDecreaseQF :call loghigh#DecreaseQFHeight()<CR>
endfunction

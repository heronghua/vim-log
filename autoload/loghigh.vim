" 存储搜索模式和搜索高亮ID
let s:last_search_pattern = ''
let s:search_highlight_id = 0

" 搜索函数
function! loghigh#Search(pattern) abort
  " 保存搜索模式用于高亮
  let s:last_search_pattern = a:pattern
  
  " 保存当前窗口
  let l:current_win = winnr()
  
  " 获取当前缓冲区内容
  let l:lines = getline(1, '$')
  let l:matches = []
  let l:index = 1
  
  " 编译正则表达式
  try
    let l:regex = a:pattern
    if l:regex !~# '^\\v'
      let l:regex = '\v' . l:regex
    endif
  catch
    echo "Invalid regex pattern: " . a:pattern
    return
  endtry
  
  " 查找匹配行
  for line in l:lines
    if match(line, l:regex) >= 0
      call add(l:matches, {
            \ 'bufnr': bufnr('%'),
            \ 'lnum': l:index,
            \ 'text': line
            \ })
    endif
    let l:index += 1
  endfor
  
  if empty(l:matches)
    echo "No matches found for: " . a:pattern
    return
  endif
  
  " 设置 quickfix 列表
  call setqflist(l:matches)
  
  " 打开 quickfix 窗口
  copen
  
  " 调整 quickfix 窗口大小
  call s:adjust_quickfix_size()
  
  " 应用日志高亮
  call loghigh#ApplyQFHighlight()
  
  " 返回原窗口
  execute l:current_win . 'wincmd w'
endfunction

" 调整 quickfix 窗口大小
function! s:adjust_quickfix_size() abort
  if &filetype != 'qf'
    return
  endif
  
  " 获取配置值或使用默认值
  let ratio = get(g:, 'loghigh_qf_height_ratio', 0.8)
  let min_height = get(g:, 'loghigh_qf_min_height', 10)
  let max_height = get(g:, 'loghigh_qf_max_height', 40)
  
  " 计算高度
  let total_lines = &lines
  let qf_height = float2nr(total_lines * ratio)
  
  " 应用高度限制
  if qf_height < min_height
    let qf_height = min_height
  elseif qf_height > max_height
    let qf_height = max_height
  endif
  
  " 设置窗口高度
  execute 'resize ' . qf_height
endfunction

" 增加 quickfix 窗口高度
function! loghigh#IncreaseQFHeight() abort
  " 找到 quickfix 窗口
  let qf_win = s:find_quickfix_window()
  if qf_win == -1
    echo "Quickfix window not found"
    return
  endif
  
  " 切换到 quickfix 窗口
  let curr_win = winnr()
  execute qf_win . 'wincmd w'
  
  " 增加高度 (1 行)
  execute 'resize +1'
  
  " 返回原窗口
  execute curr_win . 'wincmd w'
endfunction

" 减少 quickfix 窗口高度
function! loghigh#DecreaseQFHeight() abort
  " 找到 quickfix 窗口
  let qf_win = s:find_quickfix_window()
  if qf_win == -1
    echo "Quickfix window not found"
    return
  endif
  
  " 切换到 quickfix 窗口
  let curr_win = winnr()
  execute qf_win . 'wincmd w'
  
  " 减少高度 (1 行)
  execute 'resize -1'
  
  " 返回原窗口
  execute curr_win . 'wincmd w'
endfunction

" 查找 quickfix 窗口 (私有函数)
function! s:find_quickfix_window() abort
  for i in range(1, winnr('$'))
    if getwinvar(i, '&buftype') == 'quickfix'
      return i
    endif
  endfor
  return -1
endfunction

" 应用高亮到 quickfix - 添加搜索关键词高亮
function! loghigh#ApplyQFHighlight() abort
  " 确保在 quickfix 窗口
  if &filetype != 'qf'
    return
  endif
  
  " 清除旧语法
  syntax clear
  
  " 匹配整个 quickfix 行（直接显示纯文本）
  syntax match qfLogEntry /^.*$/ contains=qfLogDebug,qfLogInfo,qfLogWarn,qfLogError,qfLogFatal,qfLogVerbose
  
  " 定义日志语法规则 - 根据时间格式区分日志级别
  syntax match qfLogDebug /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} D.+/ contained
  syntax match qfLogInfo /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} I.+/ contained
  syntax match qfLogWarn /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} W.+/ contained
  syntax match qfLogError /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} E.+/ contained
  syntax match qfLogFatal /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} F.+/ contained

  "another style
  syntax match qfLogDebug /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} +\d+ +\d+ D.*/
  syntax match qfLogInfo /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}  +\d+ +\d+ I.*/
  syntax match qfLogWarn /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} +\d+ +\d+ W.*/
  syntax match qfLogError /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} +\d+ +\d+ E.*/
  syntax match qfLogFatal /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} +\d+ +\d+ F.*/
  syntax match qfLogVerbose /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} +\d+ +\d+ V.*/

  " 添加搜索关键词高亮 - 使用特殊组以便动态更新
  syntax match qfSearchKeyword /\v\c/ contained
  highlight qfSearchKeyword ctermfg=Red guifg=#ff0000 cterm=bold,underline gui=bold,underline
  
  " 设置高亮
  highlight qfLogDebug ctermfg=Cyan guifg=#00ffff
  highlight qfLogInfo ctermfg=Green guifg=#00ff00
  highlight qfLogWarn ctermfg=Yellow guifg=#ffff00
  highlight qfLogVerbose ctermfg=White guifg=#ffffff
  highlight qfLogError ctermfg=Red guifg=#ff0000 cterm=bold gui=bold
  highlight qfLogFatal ctermfg=Red guifg=#ff0000 cterm=bold,underline gui=bold,underline
  
  " 应用搜索关键词高亮
  call s:apply_search_highlight()
endfunction

" 应用搜索关键词高亮 - 完全修复版本
function! s:apply_search_highlight() abort
  " 安全清除之前的搜索高亮
  if s:search_highlight_id > 0
    " 方法1: 使用 silent! 防止错误
    silent! call matchdelete(s:search_highlight_id)
    
    " 方法2: 检查匹配是否存在
    let matches = getmatches()
    let match_exists = 0
    
    for match in matches
      if match['id'] == s:search_highlight_id
        let match_exists = 1
        break
      endif
    endfor
    
    " 如果匹配存在但 silent! 未能删除，再次尝试删除
    if match_exists
      silent! call matchdelete(s:search_highlight_id)
    endif
    
    let s:search_highlight_id = 0
  endif
  
  " 如果没有搜索模式或模式为空，返回
  if empty(s:last_search_pattern)
    return
  endif
  
  try
    " 创建高亮规则
    let hl_group = 'qfSearchKeyword'
    
    " 尝试创建匹配
    let s:search_highlight_id = matchadd(hl_group, s:last_search_pattern)
    
    " 验证匹配是否成功创建
    let matches = getmatches()
    let match_created = 0
    
    for match in matches
      if match['id'] == s:search_highlight_id
        let match_created = 1
        break
      endif
    endfor
    
    if !match_created
      echo "Failed to create search highlight"
      let s:search_highlight_id = 0
    endif
    
  catch /^Vim\%((\a\+)\)\=:E/
    " 显示错误但继续执行
    echo "Error applying search highlight: " . v:exception
    let s:search_highlight_id = 0
  endtry
endfunction

" 自动为 quickfix 应用日志高亮
autocmd FileType qf call loghigh#ApplyQFHighlight()

" 当 quickfix 窗口内容变化时重新应用高亮
autocmd BufWinEnter quickfix call s:apply_search_highlight()

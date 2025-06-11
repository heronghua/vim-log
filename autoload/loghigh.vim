" 存储搜索模式和搜索高亮ID
let s:last_search_pattern = ''
let s:search_highlight_ids = []

" 搜索函数 {{{
function! loghigh#Search(pattern) abort
  " 保存原始搜索模式
  let s:last_search_pattern = a:pattern
  
  " 保存当前窗口
  let l:current_win = winnr()
  
  " 获取当前缓冲区内容
  let l:lines = getline(1, '$')
  let l:matches = []
  let l:index = 1
  
  " 编译正则表达式 - 处理所有特殊字符
  try
    let l:regex = s:create_safe_search_regex(a:pattern)
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
"}}}

" 创建安全的搜索正则表达式 - 处理所有特殊字符{{{
function! s:create_safe_search_regex(pattern) abort
  " 如果模式以 \v 开头，直接使用
  if a:pattern =~# '^\\v'
    return a:pattern
  endif
  
  " 检查是否需要添加分组
  if s:need_grouping(a:pattern)
    return '\v(' . a:pattern . ')'
  endif
  
  " 否则添加 \v 前缀
  return '\v' . a:pattern
endfunction
"}}}

" 检查是否需要添加分组 {{{
function! s:need_grouping(pattern) abort
  " 包含未转义的 | 符号
  if a:pattern =~ '\(^\|[^\\]\)|'
    return 1
  endif
  
  " 包含未转义的 ( 或 ) 符号
  if a:pattern =~ '\(^\|[^\\]\)(' || a:pattern =~ '\(^\|[^\\])\)'
    return 1
  endif
  
  " 包含未转义的 + 或 * 符号
  if a:pattern =~ '\(^\|[^\\]\)[+*]'
    return 1
  endif
  
  " 包含字符集 [...]
  if a:pattern =~ '\[.*\]'
    return 1
  endif
  
  return 0
endfunction
"}}}

" 应用搜索关键词高亮 - 处理所有特殊字符{{{
function! s:apply_search_highlight() abort
  " 安全清除之前的搜索高亮
  for id in s:search_highlight_ids
    silent! call matchdelete(id)
  endfor
  let s:search_highlight_ids = []
  
  " 如果没有搜索模式或模式为空，返回
  if empty(s:last_search_pattern)
    return
  endif
  
  try
    " 创建高亮规则
    let hl_group = 'qfSearchKeyword'
    
    " 处理复杂模式 - 拆分为简单模式
    let patterns = loghigh#Split_complex_pattern(s:last_search_pattern)
    
    for pattern in patterns
      " 创建安全的显示模式
      let display_pattern = s:create_safe_display_pattern(pattern)
      
      " 尝试创建匹配
      let id = matchadd(hl_group, display_pattern, 10)
      call add(s:search_highlight_ids, id)
    endfor
  catch /^Vim\%((\a\+)\)\=:E/
    " 显示错误但继续执行
    echo "Error applying search highlight: " . v:exception
  endtry
endfunction
"}}}

" 拆分复杂模式为简单模式 {{{
function! loghigh#Split_complex_pattern(pattern) abort
  " 如果模式是简单的单词，直接返回
  if a:pattern =~ '^\w\+$'
    return [a:pattern]
  endif
  
  " 处理 | 分隔的多个模式
  if a:pattern =~ '\(^\|[^\\]\)|'
    let patterns = split(a:pattern, '\(^\|[^\\]\)\zs|')
    
    " 清理转义字符
    return map(patterns, {_, p -> substitute(p, '\\|', '|', 'g')})
  endif
  
  " 无法拆分的复杂模式
  return [a:pattern]
endfunction
"}}}

" 创建安全的显示模式 {{{
function! s:create_safe_display_pattern(pattern) abort
  " 如果是简单单词，直接返回
  if a:pattern =~ '^\w\+$'
    return a:pattern
  endif
  
  " 处理包含特殊字符的模式
  if a:pattern =~ '\(^\|[^\\]\)[.*+?()|{}\[\]]'
    return '\v(' . a:pattern . ')'
  endif
  
  " 其他情况直接返回
  return a:pattern
endfunction
"}}}

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

" 自动为 quickfix 应用日志高亮
autocmd FileType qf call loghigh#ApplyQFHighlight()

" 当 quickfix 窗口内容变化时重新应用高亮
autocmd BufWinEnter quickfix call s:apply_search_highlight()

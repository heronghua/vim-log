if exists('b:current_syntax') && b:current_syntax == 'log'
  finish
endif

syntax clear

" 定义匹配规则 - 与 quickfix 语法保持一致
syntax match logDebug /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} D.*$/
syntax match logInfo /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} I.*$/
syntax match logWarn /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} W.*$/
syntax match logError /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} E.*$/
syntax match logFatal /\v\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3} F.*$/

" 设置高亮
highlight logDebug ctermfg=Cyan guifg=#00ffff
highlight logInfo ctermfg=Green guifg=#00ff00
highlight logWarn ctermfg=Yellow guifg=#ffff00
highlight logError ctermfg=Red guifg=#ff0000 cterm=bold gui=bold
highlight logFatal ctermfg=Red guifg=#ff0000 cterm=bold,underline gui=bold,underline

let b:current_syntax = 'log'

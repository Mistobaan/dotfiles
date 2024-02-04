" configurations for https://github.com/airblade/vim-gitgutter

let g:gitgutter_enabled = 1

let g:gitgutter_override_sign_column_highlight = 0

let g:gitgutter_async = 1


let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'
let g:gitgutter_sign_removed_first_line = '-'
let g:gitgutter_sign_modified_removed = '-'

" highlight clear SignColumn
" highlight! GitGutterAdd ctermfg=green guifg=green
" highlight! GitGutterChange ctermfg=yellow guifg=orange
" highlight! GitGutterDelete ctermfg=red guifg=red
" highlight! GitGutterChangeDelete ctermfg=yellow guifg=red


" highlight clear SignColumn
" highlight GitGutterAdd ctermfg=green guifg=darkgreen
" highlight GitGutterChange ctermfg=yellow guifg=darkyellow
" highlight GitGutterDelete ctermfg=red guifg=darkred
" highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow

"colorscheme solarized
"set background=light

" Sign Column made by solarized color is strange, clear it.
highlight clear SignColumn

" vim-gitgutter will use Sign Column to set its color, reload it.
call gitgutter#highlight#define_highlights()


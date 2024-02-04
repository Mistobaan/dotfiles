
"If you don't want to use the <F8> key for autopep8, simply remap it to another
"key.
autocmd FileType python map <buffer> <F8> :call Autopep8()<CR>

" Do not fix these errors/warnings (default: E226,E24,W6)
" let g:autopep8_ignore=""

"Fix only these errors/warnings (e.g. E4,W)
let g:autopep8_select=""

"Maximum number of additional pep8 passes (default: 100)
let g:autopep8_pep8_passes=100

"Set maximum allowed line length (default: 79)
let g:autopep8_max_line_length=79

"Enable possibly unsafe changes (E711, E712) (default: non defined)
let g:autopep8_aggressive=1

"Number of spaces per indent level (default: 4)
let g:autopep8_indent_size=4

"Disable show diff window
let g:autopep8_disable_show_diff=0

" YouCompleteMe https://github.com/Valloric/YouCompleteMe


let g:ycm_server_python_interpreter = '/usr/bin/python3'

"let g:ycm_autoclose_preview_window_after_completion=1

" let g:ycm_dont_warn_on_startup = 0
" let g:ycm_complete_in_comments = 1
" let g:ycm_complete_in_strings = 1
" let g:ycm_collect_identifiers_from_comments_and_strings = 1

" let g:ycm_filetype_blacklist = {}

" EnableM compatible with UltiSnips (using supertab)
" http://stackoverflow.com/questions/14896327/ultisnips-and-youcompleteme
let g:ycm_key_list_select_completion   = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']

let g:SuperTabDefaultCompletionType    = '<C-n>'
let g:SuperTabCrMapping                = 0


map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

" force recompile
nnoremap <F5>  :YcmForceCompileAndDiagnostics<CR>


" trigger for autocompletion for typescript
if !exists("g:ycm_semantic_triggers")
   let g:ycm_semantic_triggers = {}
endif

let g:ycm_semantic_triggers['typescript'] = ['.']

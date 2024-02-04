"CtrlP

"show hidden files
let g:ctrlp_show_hidden = 1

let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
let g:ctrlp_custom_ignore = {
    \ 'dir': '\v[\/]\.(idea|git|hg|svn|build)$',
    \ 'file': '\v\.(exe|so|dll)$',
    \ }

let g:ctrlp_extensions = ['tag', 'buffertag', 'quickfix', 'dir', 'rtscript',
                          \ 'undo', 'line', 'changes', 'mixed', 'bookmarkdir']

" let g:ctrlp_match_window_bottom = 0
" let g:ctrlp_match_window_reversed = 0
" let g:ctrlp_custom_ignore = '\v\~$|\.(o|swp|pyc|wav|mp3|ogg|blend)$|(^|[/\\])\.(hg|git|bzr)($|[/\\])|__init__\.py'
" let g:ctrlp_working_path_mode = 0
" let g:ctrlp_dotfiles = 0

" 'r' - the nearest ancestor that contains one of these directories or files: .git .hg .svn .bzr _darcs
let g:ctrlp_working_path_mode = 'rc'

"Specify the number of recently opened files you want CtrlP to remember: >
let g:ctrlp_mruf_max = 10

" dont remember these files
let g:ctrlp_mruf_exclude = '/tmp/.*\|/temp/.*' " MacOSX/Linux


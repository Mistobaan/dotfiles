" Python functions and configuration
autocmd FileType python set omnifunc=pythoncomplete#Complete

" autocmd BufWritePre *.py normal m`:%s/\s\+$//e``

" PEP8 indentation
au FileType python set tabstop=4
au FileType python set softtabstop=4
au FileType python set shiftwidth=4
au FileType python set textwidth=79
au FileType python setlocal smarttab
au FileType python set expandtab
au FileType python set autoindent
"au FileType python set fileformat=unixlet
au FileType python set foldmethod=indent
au FileType python set foldlevel=99
au FileType python set encoding=utf-8
au FileType python syntax on
au FileType python set number

" ignore PYC files
" set NERDTreeIgnore+=['\.pyc$', '\~$'] "ignore files in NERDTree


let g:pymode_rope = 0

"Linting
let g:pymode_lint = 1
let g:pymode_lint_checkers = ['mccabe', 'pyflakes', 'pylint', 'pep257']
let g:pymode_lint_ignore = "D100,E111,C0111,D102,D101,E114"

" Auto check on save
let g:pymode_lint_write = 0

" Support virtualenv
let g:pymode_virtualenv = 1

" Enable breakpoints plugin
let g:pymode_breakpoint = 1
let g:pymode_breakpoint_bind = '<leader>b'

" syntax highlighting
let g:pymode_syntax = 1
let g:pymode_syntax_all = 1
let g:pymode_syntax_indent_errors = g:pymode_syntax_all
let g:pymode_syntax_space_errors = g:pymode_syntax_all

" Don't autofold code
let g:pymode_folding = 0
let python_highlight_all=1

"python with virtualenv support
python << EOF
import os
import sys
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  execfile(activate_this, dict(__file__=activate_this))
EOF

"python with conda support
python << EOF
import os
import sys
if 'conda' in sys.version:
    pass
EOF

" SimplyFold plugin to have less indentations
let g:SimpylFold_docstring_preview = 1

" highlight tabs and trailing spaces
set listchars=tab:>-,trail:-
set list listchars=tab:→\ ,trail:·
set list listchars=tab:→\ ,trail:·,extends:>,precedes:<,nbsp:_

autocmd FileType python &let makeprg=pylint\ --reports=n\ --msg-template=\"{path}:{line}:\ {msg_id}\ {symbol},\ {obj}\ {msg}\"\ %:p
autocmd FileType python &set errorformat=%f:%l:\ %m


" " COLOR
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" set t_Co=256
" set background=light
" set term=screen-256color-bce
" "enable 256 colors to solarized. Must be before the colorscheme commmand
" let g:solarized_termcolors=256
" colorscheme solarized
" " turn high visibility for diffmore
" let g:solarized_diffmode="high"

" set guifont=Inconsolata:h18

" " disable startup message
" set shortmess+=I
" " " paste without auto-indentation
" " set paste
" " " hide buffers, not close them
" " set hidden

" " " searching
" " set hlsearch
" " set incsearch

" " " highlight matching bracket/parenthesis
" " set showmatch


" " set cmdheight=2
" " set switchbuf=useopen
" " set numberwidth=5
" " set showtabline=2
" " set winwidth=79
" " set shell=bash


" " press esc to remove the highlight
" " nnoremap <CR> :noh<CR><CR>

" " press F3 to toggle the highlight
" nnoremap <F3> :set hlsearch!<CR>

" " remove white spaces
" " http://stackoverflow.com/questions/356126/how-can-you-automatically-remove-trailing-whitespace-in-vim
" fun! <SID>StripTrailingWhitespaces()
"     let l = line(".")
"     let c = col(".")
"     %s/\s\+$//e
"     call cursor(l, c)
" endfun

" autocmd FileType c,cpp,java,php,ruby,python autocmd BufWritePre <buffer> :call <SID>StripTrailingWhitespaces()

" autocmd Filetype html setlocal ts=2 sw=2 expandtab
" autocmd Filetype ruby setlocal ts=2 sw=2 expandtab


" " set json syntax hlight
" autocmd BufNewFile,BufRead *.json set ft=javascript

" " Prevent Vim from clobbering the scrollback buffer. See
" " http://www.shallowsky.com/linux/noaltscreen.html
" set t_ti= t_te=


" " Store temporary files in a central spot
" set backup
" set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
" set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

" " " Enable file type detection.
" " " Use the default filetype settings, so that mail gets 'tw' set to 72,
" " " 'cindent' is on in C files, etc.
" " " Also load indent files, to automatically do language-dependent indenting.
" " filetype plugin indent on
" " " use emacs-style tab completion when selecting files, etc
" " set wildmode=longest,list
" " " make tab completion for files/buffers act like bash
" " set wildmenu
" " set number

" " autocmd FileType python set


" " " Enable folding
" " set foldmethod=indent
" " set foldlevel=99

" " " Enable folding with the spacebar
" " nnoremap <space> za


" " " open new split panes to right and bottom
" " set splitbelow
" " set splitright


" " " Map Ctrl-A to start of line
" " inoremap <c-a> <Home>
" " inoremap <c-e> <End>

" " " add fugitive status line
" " set statusline="%{fugitive#statusline()}"


" " " add syntastic statusline
" " set statusline+=%#warningmsg#
" " set statusline+=%{SyntasticStatuslineFlag()}
" " set statusline+=%*

" " let g:syntastic_always_populate_loc_List = 1
" " let g:syntastic_auto_loc_list = 1
" " let g:syntastic_check_on_open = 0
" " let g:syntastic_check_on_wq = 0
" " " use ctrl+w E to do the checking
" " let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
" " nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>

" " " use python 
" " let g:syntastic_python_checkers = ['pylint']

" " " use pylintrc
" " let g:syntastic_python_pylint_args = "--rcfile=/home/fmilo/.pylintrc"

" " " set vertical split in fugitive gDiff
" " set diffopt+=vertical

" " " set the name of the tag files to search
" " set tags=.git/tags;./tags;$HOME,tags;


" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" "What this function does is that if there is no completion that could happen it will insert a tab. Otherwise it checks to see if there is an omnifunction available and, if so, uses it. Otherwise it falls back to Dictionary completion if there is a dictionary defined. Finally it resorts to simple known word completion. In general, hitting the Tab key will just do the right thing for you in any given situation.

" function! SuperCleverTab()
"   if strpart(getline('.'), 0, col('.') - 1) =~ '^\s*$'
"     return "\"
"   else
"     if &omnifunc != ''
"       return "\\"
"     elseif &dictionary != ''
"       return "\"
"     else
"       return "\"
"     endif
"   endif
" endfunction

" inoremap <Tab> <C-R>=SuperCleverTab()<cr>

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" " MULTIPURPOSE TAB KEY
" " Indent if we're at the beginning of a line. Else, do completion.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" " function! InsertTabWrapper()
" "     let col = col('.') - 1
" "     if !col || getline('.')[col - 1] !~ '\k'
" "         return "\<tab>"
" "     else
" "         return "\<c-p>"
" "     endif
" " endfunction
" " inoremap <tab> <c-r>=InsertTabWrapper()<cr>
" " inoremap <s-tab> <c-n>

" autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
" autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
" autocmd FileType css set omnifunc=csscomplete#CompleteCSS

" " Force markdown format in buffer
" autocmd BufNewFile,BufReadPost *.md set filetype=markdown


" " enable fenced code highlight in markdown block
" let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


" inoremap <C-space> <C-x><C-o>

" set ofu=sytaxcomplete



" " set clipboard=unnamed

" " Disable one diff window during a three-way diff allowing you to cut out the
" " noise of a three-way diff and focus on just the changes between two versions
" " at a time. Inspired by Steve Losh's Splice
" function! DiffToggle(window)
"   " Save the cursor position and turn on diff for all windows
"   let l:save_cursor = getpos('.')
"   windo :diffthis
"   " Turn off diff for the specified window (but keep scrollbind) and move
"   " the cursor to the left-most diff window
"   exe a:window . "wincmd w"
"   diffoff
"   set scrollbind
"   set cursorbind
"   exe a:window . "wincmd " . (a:window == 1 ? "l" : "h")
"   " Update the diff and restore the cursor position
"   diffupdate
"   call setpos('.', l:save_cursor)
" endfunction
" " Toggle diff view on the left, center, or right windows
" nmap <silent> <leader>dl :call DiffToggle(1)<cr>
" nmap <silent> <leader>dc :call DiffToggle(2)<cr>
" nmap <silent> <leader>dr :call DiffToggle(3)<cr>

" set paste

" " highlight special characters in yellow
" highlight SpecialKey term=standout ctermbg=darkred guibg=darkred

" " highlight ExtraWhiteSpaces

" highlight UnwanttedTab ctermbg=red guibg=darkred
" highlight TrailSpace guibg=red ctermbg=darkred

" match UnwanttedTab /\t/
" match TrailSpace / \+$/

" autocmd ColorScheme * highlight UnwanttedTab ctermbg=red guibg=darkred
" autocmd ColorScheme * highlight TrailSpace guibg=red ctermbg=darkred


" " disable line numbers inside the geeknote navigation window
" " autocmd FileType geeknote setlocal nonumber

" "------------
" " tells vim not to automatically reload changed files
" "set noautoread

" function! DiffWithSaved()
"   let filetype=&ft
"   diffthis
"   vnew | r # | normal! 1Gdd
"   diffthis
"   exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
" endfunction

" " sets up mappings to function

" com! DiffSaved call DiffWithSaved()
" map <Leader>ds :DiffSaved<CR>


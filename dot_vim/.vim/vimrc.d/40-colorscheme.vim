
set background=light

silent! colorscheme solarized

" Highligh Commments with light gray bg
highlight Comment ctermbg=254

" highlight in red overlength characters
highlight OverLength ctermfg=5
match OverLength /\%81v.\+/

" Only highlight the current line in the active window.
autocmd WinEnter * setlocal cursorline
autocmd WinLeave * setlocal nocursorline

" strong underline instead of background highlight
hi CursorLine term=bold cterm=bold guibg=Grey40

hi CursorLine   cterm=underline ctermbg=229 ctermfg=NONE
hi CursorColumn  cterm=NONE ctermbg=254 ctermfg=NONE

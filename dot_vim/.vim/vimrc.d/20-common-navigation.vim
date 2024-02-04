" see http://tartley.com/?p=1277
" make case sensitive tag searches
fun! MatchCaseTag()
    let ic = &ic
    set noic
    try
        exe 'tjump ' . expand('<cword>')
    finally
       let &ic = ic
    endtry
endfun

noremap <silent> <c-]> :call MatchCaseTag()<CR>

nnoremap ,cd :cd %:p:h<CR>:pwd<CR>


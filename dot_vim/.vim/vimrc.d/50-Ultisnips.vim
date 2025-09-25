" " UltiSnips completion function that tries to expand a snippet. If there's no
" " snippet for expanding, it checks for completion window and if it's
" " shown, selects first element. If there's no completion window it tries to
" " jump to next placeholder. If there's no placeholder it just returns TAB key
" function! g:UltiSnips_Complete()
"     call UltiSnips_ExpandSnippet()
"     if g:ulti_expand_res == 0
"         if pumvisible()
"             return "\<C-n>"
"         else
"             call UltiSnips_JumpForwards()
"             if g:ulti_jump_forwards_res == 0
"                return "\<TAB>"
"             endif
"         endif
"     endif
"     return ""
" endfunction

" function! g:UltiSnips_Reverse()
"   call UltiSnips#JumpBackwards()
"   if g:ulti_jump_backwards_res == 0
"     return "\<C-P>"
"   endif

"   return ""
" endfunction



let g:UltiSnipsExpandTrigger = "<nop>"
let g:ulti_expand_or_jump_res = 0

function! ExpandSnippetOrCarriageReturn()
    let snippet = UltiSnips#ExpandSnippetOrJump()
    if g:ulti_expand_or_jump_res > 0
        return snippet
    else
        return "\<CR>"
    endif
endfunction

" inoremap <expr> <CR> ExpandSnippetOrCarriageReturn()

inoremap <expr> <CR> pumvisible() ? "<C-R>=ExpandSnippetOrCarriageReturn()<CR>" : "\<CR>"

" au BufEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<cr>"

" let g:UltiSnipsExpandTrigger = "<CR>"
" let g:UltiSnipsJumpForwardTrigger = "<C-j>"
" let g:UltiSnipsJumpBackwardTrigger = "<C-k>"


" let g:UltiSnipsExpandTrigger = "<tab>"
" let g:UltiSnipsJumpForwardTrigger = "<tab>"
" let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" let g:UltiSnipsEditSplit='vertical'

" let g:ycm_key_list_select_completion=["<tab>"]
" let g:ycm_key_list_previous_completion=["<S-tab>"]

" let g:UltiSnipsJumpForwardTrigger="<tab>"
" let g:UltiSnipsJumpBackwardTrigger="<S-tab>"
" let g:UltiSnipsExpandTrigger="<nop>"
" let g:ulti_expand_or_jump_res = 0
" function! <SID>ExpandSnippetOrReturn()
"   let snippet = UltiSnips#ExpandSnippetOrJump()
"   if g:ulti_expand_or_jump_res > 0
"     return snippet
"   else
"     return "\<CR>"
"   endif
" endfunction

" "inoremap <expr> <CR> pumvisible() ? "<C-R>=<SID>ExpandSnippetOrReturn()<CR>" : "\<CR>"

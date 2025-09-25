"VIMUX

let g:VimuxOrientation = "h"
let g:VimuxRunnerType = "pane"

let g:VimuxTmuxCommand = "tmux"
let g:VimuxHeight = "40"


function! VimuxSlime()
  call VimuxSendText(@v)
  call VimuxSendKeys("Enter")
endfunction

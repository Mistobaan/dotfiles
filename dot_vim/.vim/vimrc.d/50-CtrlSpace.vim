" CtrlSpace
" https://github.com/vim-ctrlspace/vim-ctrlspace

set nocompatible
set hidden

if has("gui_running")
    let g:CtrlSpaceSymbols = { "File": "◯", "CTab": "▣", "Tabs": "▢" }
endif

if executable("ag")
    let g:CtrlSpaceGlobCommand = 'ag -l --nocolor -g ""'
endif

let g:CtrlSpaceSearchTiming = 500

hi link CtrlSpaceNormal   PMenu
hi link CtrlSpaceSelected PMenuSel
hi link CtrlSpaceSearch   Search
hi link CtrlSpaceStatus   StatusLine


" Ctrl-Space can automatically save your workspace status based on configurations below:

let g:CtrlSpaceLoadLastWorkspaceOnStart = 1
let g:CtrlSpaceSaveWorkspaceOnSwitch = 1
let g:CtrlSpaceSaveWorkspaceOnExit = 1

" Turns on the default mapping. If you turn off this option (`0`) you will
" have to provide your own mapping to trigger the plugin. Default value:
let g:CtrlSpaceSetDefaultMapping = 1

let g:CtrlSpaceDefaultMappingKey = "<C-Space>"



runtime! bundle/vim-pathogen/vimrc.d/config.vim
runtime! bundle/vim-pathogen/autoload/pathogen.vim

execute pathogen#infect()

"runtime! vimrc.d/[[:digit:]][[:digit:]]*.vim
runtime! vimrc.d/2[[:digit:]]*.vim
runtime! vimrc.d/3[[:digit:]]*.vim
runtime! vimrc.d/4[[:digit:]]*.vim
runtime! vimrc.d/5[[:digit:]]*.vim
runtime! bundle/*/vimrc.d/*.vim

Helptags

#!/bin/sh

set -e

sudo apt-get remove --purge vim vim-runtime vim-gnome vim-tiny vim-common vim-gui-common
sudo apt-get install liblua5.1-dev luajit libluajit-5.1 python-dev ruby-dev libperl-dev mercurial libncurses5-dev libgnome2-dev libgnomeui-dev libgtk2.0-dev libatk1.0-dev libbonoboui2-dev libcairo2-dev libx11-dev

sudo mkdir -p /usr/include/lua5.1/include
sudo ln -s /usr/include/luajit-2.0 /usr/include/lua5.1/include || echo "ok";

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


cd $HOME
if [ ! -d  $HOME/vim]; then
  git clone https://github.com/vim/vim.git --depth 1
fi

cd vim/src
make distclean

./configure --with-features=huge \
            --enable-multibyte \
            --enable-largefile \
            --enable-rubyinterp \
            --enable-netbeans \
            --enable-pythoninterp \
            --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
            --enable-python3interp \
            --with-python3-config-dir=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu \
            --enable-luainterp \
            --with-luajit \
            --with-lua-prefix=/usr/include/lua5.1 \
            --enable-gui=auto \
            --enable-fail-if-missing \
            --enable-cscope \
            --prefix=/usr 2>config_err.log >config.log || cat config_err.log
make VIMRUNTIMEDIR=/usr/share/vim/vim80
sudo make install
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
sudo update-alternatives --set editor /usr/bin/vim
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
sudo update-alternatives --set vi /usr/bin/vim

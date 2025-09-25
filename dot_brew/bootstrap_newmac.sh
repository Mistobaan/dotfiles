#!/bin/bash

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

# Install GNU core utilities (those that come with OS X are outdated)
brew install coreutils

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

# Install Bash 4
brew install bash

# Install more recent versions of some OS X tools
brew tap homebrew/dupes
brew install homebrew/dupes/grep

binaries=(
  #graphicsmagick
  #webkit2png
  #rename
  #zopfli
  #ffmpeg
  #python
  #sshfs
  trash # http://hasseg.org/trash/ move to trash
  node  #
  tree  #
  ack   # faster search
  hub   # list issues from command line
  git   # :)
)

echo "installing binaries..."
brew install ${binaries[@]}


brew cleanup

brew install caskroom/cask/brew-cask

# Install Apps
mac_finder_extensions=(
  alfred
  qlcolorcode
  qlprettypatch
  qlstephen # A QuickLook plug-in that lets you view plain text files without a file extension
  qlmarkdown
  quicklook-json
  screenflick
  # development
  iterm2
  sourcetree
  slack
  transmit
  appcleaner
  dropbox
  google-chrome
  firefox
  spotify
  vagrant
  flash # flash player
  shiori
  sublime-text2
  virtualbox
  atom
  flux
  sketch
  vlc
  skype
  transmission
)

# Install apps to /Applications
# Default is: /Users/$user/Applications
echo "installing apps..."
brew cask install --appdir="/Applications" ${mac_finder_extensions[@]}

brew cask alfred link

brew tap caskroom/fonts

# fonts
fonts=(
  font-m-plus
  font-clear-sans
  font-roboto
)

# install fonts
echo "installing fonts..."
brew cask install ${fonts[@]}

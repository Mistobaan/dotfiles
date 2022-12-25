#!/bin/sh

export GITHUB_USERNAME=Mistobaan
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
cd $HOME
chezmoi init
chezmoi update

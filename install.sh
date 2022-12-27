#!/bin/sh
cd $HOME
export GITHUB_USERNAME=Mistobaan
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
cd $HOME
./bin/chezmoi init --apply $GITHUB_USERNAME
./bin/chezmoi update

#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

if ! [[ -d storybook/node_modules ]] ; then
  yarn storybook:install
fi

yarn tailwindcss:build
yarn --cwd ./storybook start

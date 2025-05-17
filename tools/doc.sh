#!/bin/sh

# Generate documentation for the rws.nvim plugin using vimcats.
# Run this script from the root of the repository:
# $ sh tools/docs.sh

mkdir -p "$PWD/doc"
cargo install vimcats --features=cli
vimcats \
  lua/rws/init.lua \
  lazy.lua \
  >"$PWD/doc/modechar.nvim.txt"

less "$PWD/doc/modechar.nvim.txt"

#!/bin/sh

# Generate documentation for the rws.nvim plugin using vimcats.
# Run this script from the root of the repository:
# $ sh tools/docs.sh

mkdir -p "$PWD/doc"
cargo install vimcats --features=cli
vimcats \
  lua/rws/init.lua \
  lua/rws/opts-swap.lua \
  lazy.lua \
  >"$PWD/doc/rws.nvim.txt"

less "$PWD/doc/rws.nvim.txt"

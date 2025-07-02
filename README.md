# crate-fzf

A Vim plugin to search and add Rust crates to `Cargo.toml` using fzf. It uses `cargo search` to find crates, displays crate names in the fzf main window and descriptions in the preview window, and allows selecting versions and features via the crates.io API.

## Requirements

- Vim or Neovim
- [fzf](https://github.com/junegunn/fzf)
- [fzf.vim](https://github.com/junegunn/fzf.vim)
- `cargo`, `curl`, `jq`, `grep`, `cut`, `fold` (available on most Unix systems)

## Installation

Using [Vim-Plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'username/crate-fzf'

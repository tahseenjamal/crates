" plugin/crate.vim
" Prevent loading the plugin multiple times
if exists('g:loaded_crate_fzf')
  finish
endif
let g:loaded_crate_fzf = 1

" Define the :Crate command
command! -nargs=? Crate call crates#SearchFZF(<f-args>)

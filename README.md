A Vim plugin for searching and adding Rust crates to Cargo.toml using fzf. This plugin streamlines the process of finding Rust crates via cargo search, displaying crate names in the main fzf window with their descriptions in a preview window, and allowing users to select specific versions and features through the crates.io API. It integrates seamlessly with Vim, making it easy to manage Rust dependencies directly from your editor.
Features

Search Crates: Run :Crate [search_query] to search for Rust crates using cargo search. If no query is provided, it uses the crate name under the cursor or prompts for input.
fzf Integration: Displays crate names in the fzf main window with descriptions (e.g., "Scripts for parsing UniParc XML files..." for uniparc_xml_parser) in a preview window.
Version Selection: Select from available crate versions fetched from the crates.io API.
Feature Selection: Choose optional features for crates (e.g., default, form for axum), with automatic skipping for featureless crates (e.g., uniparc_xml_parser).
Robust Error Handling: Prevents errors like Vim’s E282 by using temporary files for API calls and handles cases where crates have no features or API requests fail.
Debugging Support: Includes detailed debug output via :messages to troubleshoot issues with crate searches, API responses, or preview window rendering.

Requirements

Vim : Compatible with Vim 8.0+
fzf: The command-line fuzzy finder (junegunn/fzf).
fzf.vim: Vim integration for fzf (junegunn/fzf.vim).

System Tools:
cargo: For searching crates (part of the Rust toolchain).
curl: For fetching version and feature data from crates.io.
jq: For parsing JSON API responses.
grep, cut, fold: For rendering descriptions in the fzf preview window (standard on Unix-like systems, including macOS).



Verify dependencies:
vim --version
fzf --version
cargo --version
curl --version
jq --version
grep --version
cut --version
fold --version

Installation
Install using Vim-Plug:

Add the following to your ~/.vimrc or ~/.config/nvim/init.vim:
call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tahseenjamal/crates'
call plug#end()


Run :PlugInstall in Vim to install the plugin.

Verify installation with :PlugStatus. Ensure crates is listed as installed.


For other plugin managers (e.g., Vundle, packer.nvim), adjust the plugin declaration accordingly.
Usage

Run the :Crate [search_query or crate name]

If search_query is provided (e.g., :Crate csv file parser), it searches for crates matching the query.
If no query is provided, it uses the crate name under the cursor (e.g., axum in axum = "0.7.7") or prompts for input.

In the fzf window:
Browse crate names (e.g., uniparc_xml_parser, axum).
View crate descriptions in the preview window (e.g., "Scripts for parsing UniParc XML files..." for uniparc_xml_parser).
Press Enter to select a crate.


Select a version from the list of available versions.
If the crate has features (e.g., axum has default, form), select features using fzf’s multi-select (Tab to toggle, Enter to confirm). Featureless crates (e.g., uniparc_xml_parser) skip this step.
The plugin runs cargo add to update Cargo.toml with the selected crate, version, and features, displaying the output in a temporary buffer.

Example:
:Crate csv file parser


fzf shows crates like uniparc_xml_parser, csv_csp.
Preview shows descriptions (e.g., "Scripts for parsing..." for uniparc_xml_parser).
Select axum, choose version 0.7.7, select features, and Cargo.toml is updated:axum = { version = "0.7.7", features = ["default", "form"] }



Configuration
The plugin uses fzf’s default keybindings (Enter to select, Ctrl-t for tab split, etc.). To customize fzf behavior, set g:fzf_action or FZF_DEFAULT_OPTS in your environment:
" Example: Custom fzf keybindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit',
  \ 'enter': 'select'
  \ }

# Example: Set fzf options in ~/.zshrc or ~/.bashrc
export FZF_DEFAULT_OPTS='--height=40% --preview-window right:50%:wrap'

Debugging
If you encounter issues (e.g., empty preview window, missing features, or errors like E117):

Check Messages:
:messages

Look for debug output like:
Debug: Wrote descriptions to /var/folders/.../desc_temp
Debug: First few lines: uniparc_xml_parser|Scripts for parsing..., csv_csp|converting csv file...
Debug: API response for axum@0.7.7: ...


Test Preview Command:
echo "uniparc_xml_parser|Scripts for parsing UniParc XML files..." > /tmp/test_desc
grep -F "^uniparc_xml_parser|" /tmp/test_desc | cut -d"|" -f2- | fold -w 50

Expected:
Scripts for parsing UniParc XML files downloaded from
the Uniprot website into CSV files.


Test Feature Fetching:
curl -s https://crates.io/api/v1/crates/axum/0.7.7 | jq -r ".version.features | keys[]?"
curl -s https://crates.io/api/v1/crates/uniparc_xml_parser/0.2.1 | jq -r ".version.features | keys[]?"


axum should list features (e.g., default, form).
uniparc_xml_parser should return empty output (no features).


Check Dependencies:
vim --version
fzf --version
cargo --version
curl --version
jq --version
grep --version
cut --version
fold --version


Minimal Config Test:
set nocompatible
filetype plugin indent on
call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tahseenjamal/crates'
call plug#end()


Report Issues:

Share :messages output.
Provide Vim/Neovim version (:version).
Include macOS version, Rust version (rustc --version), and fzf version (fzf --version).
Describe any errors or unexpected behavior (e.g., double Enter presses, missing preview).



Contributing
Contributions are welcome! To contribute:

Fork the repository: tahseenjamal/crates.
Create a feature branch: git checkout -b feature-name.
Commit changes: git commit -m "Add feature-name".
Push to your fork: git push origin feature-name.
Open a pull request.

Please include tests or examples for new features and update this README.md if necessary.
License
MIT License. See LICENSE for details.
Acknowledgments

Built with fzf and fzf.vim.
Inspired by the need for efficient Rust dependency management in Vim.
Thanks to the Rust community for the crates.io API.

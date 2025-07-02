" autoload/crate.vim
function! crates#SearchFZF(...) abort
  let g:crate_orig_bufnr = bufnr('%')
  let g:crate_orig_lnum = line('.')

  " Step 1: Get search query
  if a:0 > 0
    let l:search_query = a:1
  else
    let l:line = getline('.')
    let l:match = matchlist(l:line, '^\s*\("\?\)\(\k\+\)\("\?\)\s*=')
    if !empty(l:match)
      let l:search_query = l:match[2]
    else
      let l:search_query = input('Enter crate name or description: ')
    endif
  endif

  " Step 2: Validate search query
  if empty(l:search_query)
    echohl ErrorMsg | echom 'Empty search query' | echohl None
    return
  endif

  " Step 3: Search crates using cargo search
  let l:cargo_command = 'cargo search ' . shellescape(l:search_query) . ' --limit 50'
  let l:crates_raw = systemlist(l:cargo_command)

  " Debug: Check if cargo search failed
  if v:shell_error != 0
    echohl ErrorMsg | echom 'Cargo search failed: ' . l:cargo_command | echohl None
    echohl ErrorMsg | echom 'Error output: ' . join(l:crates_raw, "\n") | echohl None
    return
  endif

  " Step 4: Parse cargo search output
  let l:crates = []
  let l:descriptions = {}
  for l:line in l:crates_raw
    if empty(l:line) || l:line =~# '^\.\.\.' || l:line =~# '^note:' || l:line !~# '^\s*\k\+\s*=\s*".*"'
      continue
    endif
    let l:parts = split(l:line, '=')
    if len(l:parts) < 2
      continue
    endif
    let l:crate_name = trim(l:parts[0])
    if empty(l:crate_name) || l:crate_name =~# '[^a-zA-Z0-9_-]'
      continue
    endif
    let l:desc_parts = split(l:line, '#')
    let l:crate_desc = len(l:desc_parts) > 1 ? trim(l:desc_parts[1]) : 'No description'
    let l:crate_desc = substitute(l:crate_desc, '\n', ' ', 'g')
    call add(l:crates, l:crate_name)
    let l:descriptions[l:crate_name] = l:crate_desc
  endfor

  " Step 5: Check if crates list is empty
  if empty(l:crates)
    echohl ErrorMsg | echom 'No crates found for query: ' . l:search_query | echohl None
    return
  endif

  " Step 6: Write descriptions to a temporary file for preview
  let l:desc_temp_file = tempname()
  let l:desc_lines = []
  for l:crate in l:crates
    let l:escaped_desc = substitute(l:descriptions[l:crate], '|', '\\|', 'g')
    call add(l:desc_lines, l:crate . '|' . l:escaped_desc)
  endfor
  call writefile(l:desc_lines, l:desc_temp_file)
  echom 'Debug: Wrote descriptions to ' . l:desc_temp_file
  echom 'Debug: First few lines: ' . join(l:desc_lines[:2], ', ')

  " Step 7: Show crate list via FZF with description in preview
  call fzf#run(fzf#wrap({
        \ 'source': l:crates,
        \ 'sink': function('crates#SelectCrate', [l:desc_temp_file]),
        \ 'options': [
        \   '--prompt', 'Select crate> ',
        \   '--preview', 'grep -F "^{1}|" ' . shellescape(l:desc_temp_file) . ' | cut -d"|" -f2- | fold -w 50',
        \   '--preview-window', 'right:50%:wrap'
        \ ],
        \ 'window': {'width': 0.9, 'height': 0.6}
        \ }))
endfunction

function! crates#SelectCrate(desc_temp_file, selected) abort
  call delete(a:desc_temp_file)
  let g:crate_name = a:selected
  if empty(g:crate_name) || g:crate_name =~# '[^a-zA-Z0-9_-]'
    echohl ErrorMsg | echom 'Invalid crate name: ' . g:crate_name | echohl None
    return
  endif

  let l:temp_file = tempname()
  let l:versions_command = 'curl -s https://crates.io/api/v1/crates/' . g:crate_name . ' > ' . l:temp_file
  call system(l:versions_command)
  if v:shell_error != 0
    echohl ErrorMsg | echom 'Failed to fetch versions for: ' . g:crate_name | echohl None
    call delete(l:temp_file)
    return
  endif
  let l:versions = systemlist('jq -r ".versions[].num" ' . l:temp_file)
  call delete(l:temp_file)
  if v:shell_error != 0 || empty(l:versions)
    echohl ErrorMsg | echom 'No versions found for crate: ' . g:crate_name | echohl None
    echohl ErrorMsg | echom 'Error output: ' . join(l:versions, "\n") | echohl None
    return
  endif

  call fzf#run(fzf#wrap({
        \ 'source': l:versions,
        \ 'sink': function('crates#ApplyVersion'),
        \ 'prompt': 'Select version for ' . g:crate_name . '> '
        \ }))
endfunction

function! crates#ApplyVersion(version) abort
  let l:line = getline(g:crate_orig_lnum)
  if l:line =~# '^\s*["' . "'" . ']*' . g:crate_name . '["' . "'" . ']*\s*='
    let l:newline = substitute(l:line, '\("[^"]*"\)', '"' . a:version . '"', '')
    call setline(g:crate_orig_lnum, l:newline)
    echom 'Updated ' . g:crate_name . ' to version ' . a:version
  else
    let l:temp_file = tempname()
    let l:api_url = 'https://crates.io/api/v1/crates/' . g:crate_name . '/' . a:version
    let l:features_command = 'curl -s ' . l:api_url . ' > ' . l:temp_file
    call system(l:features_command)
    if v:shell_error != 0
      echohl ErrorMsg | echom 'Failed to fetch features for: ' . g:crate_name . '@' . a:version | echohl None
      call delete(l:temp_file)
      let l:features = []
    else
      let l:json = join(readfile(l:temp_file), "\n")
      let l:features = systemlist('jq -r ".version.features | keys[]?" ' . l:temp_file)
      call delete(l:temp_file)
      echom 'Debug: API response for ' . g:crate_name . '@' . a:version . ': ' . strpart(l:json, 0, 100) . '...'
      if v:shell_error != 0 || (empty(l:features) && l:json =~# '"features":\s*{\s*}' || l:json =~# '"features":\s*null')
        let l:features = []
        echom 'No features found for ' . g:crate_name . '@' . a:version . ', proceeding without features.'
      endif
    endif

    if !empty(l:features)
      call fzf#run(fzf#wrap({
            \ 'source': l:features,
            \ 'sink*': function('crates#ApplyFeatures', [a:version]),
            \ 'options': ['--multi', '--prompt', 'Select features for ' . g:crate_name . '@' . a:version . '> '],
            \ }))
    else
      call crates#ApplyFeatures(a:version, [])
    endif
  endif
endfunction

function! crates#ApplyFeatures(version, selected_features) abort
  let l:cmd = 'cargo add ' . g:crate_name . '@' . a:version
  if !empty(a:selected_features)
    let l:cmd .= ' --features "' . join(a:selected_features, ' ') . '"'
  endif

  let l:output = systemlist(l:cmd)
  if v:shell_error != 0
    echohl ErrorMsg | echom 'Failed to run: ' . l:cmd | echohl None
    echohl ErrorMsg | echom 'Error output: ' . join(l:output, "\n") | echohl None
    return
  endif

  new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  call setline(1, ['Running: ' . l:cmd, '-----------------------------'] + l:output)
  redraw | sleep 2000m
  bd!

  echom 'Added ' . g:crate_name . '@' . a:version . ' with features: ' . (empty(a:selected_features) ? 'none' : join(a:selected_features, ', '))
endfunction

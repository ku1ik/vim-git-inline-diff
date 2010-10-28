map <silent> <Leader>d :call <SID>gitDiff()<CR>

hi SignColumn guifg=#7c7c7c guibg=#000000 gui=NONE
hi scmLineAdded guibg=#65b042 guifg=#65b042
hi scmLineChanged guibg=#3387cc guifg=#3387cc
hi scmLineRemoved guifg=#ff0000

sign define scmLineAdded text=_ texthl=scmLineAdded
sign define scmLineChanged text=_ texthl=scmLineChanged
sign define scmLineRemoved text=__ texthl=scmLineRemoved
sign define scmGhost

ruby << EOF
$SIGNS = Hash.new { |h,k| h[k] = [] }
EOF

function! s:gitDiff()
  set updatetime=1000

  let g:scmBufPath = expand("%:p")

  if g:scmBufPath == ""
    return
  endif

  let g:scmBufDir = expand("%:p:h")

  let oldFilePath = tempname()
  let newFilePath = tempname()

  let out = system('git show HEAD:' . bufname('%') . ' > ' . oldFilePath)
  if v:shell_error
    return
  endif

  let lines = getline(1, 1000)
  ruby << EOF
    lines = VIM::evaluate('lines')
    File.open(VIM::evaluate('newFilePath'), 'w') { |f| f.write(lines.join("\n")) }
EOF

  let out = system('cd ' . g:scmBufDir . ' && /usr/bin/diff ' . oldFilePath . ' ' . newFilePath)
  " let out = system('cd ' . g:scmBufDir . ' && /usr/bin/diff ' . oldFilePath . ' ' . newFilePath . ' | grep "^[0-9]\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\+\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\(,[0-9]\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\+\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\)\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\?[acd][0-9]\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\+\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\(,[0-9]\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\+\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\)\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\?"')

  ruby << EOF
  file = VIM::evaluate("g:scmBufPath")
  diff = VIM::evaluate('out')

  # workaround for flickering signs column
  VIM::command("sign place 1 line=1 name=scmGhost file=#{file}") unless $SIGNS[file].empty?

  # unplace signs in this file
  $SIGNS[file].each do |line|
    VIM::command("sign unplace #{line} file=#{file}")
  end
  $SIGNS[file] = []

  diff.split("\n").each do |change|
    next unless change =~ /^\d+(?:,\d+)*([acd])(\d+(?:,\d+)*)$/
    lines = $2.split(",")

    range = (lines[0].to_i..(lines[1] || lines[0]).to_i)

    name = case $1
    when 'a'
      'scmLineAdded'
    when 'c'
      'scmLineChanged'
    when 'd'
      'scmLineRemoved'
    end

    range.each do |n|
      VIM::command("sign place #{n} line=#{n} name=#{name} file=#{file}")
      $SIGNS[file] << n
    end
  end

  # workaround for flickering signs column
  VIM::command("sign unplace 1 file=#{file}") if $SIGNS[file].empty?
EOF
endfunction

set updatetime=1000

autocmd CursorHold * call <SID>gitDiff()

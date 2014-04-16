" commentary.vim - Comment stuff out
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      wilywampa's fork
" GetLatestVimScripts: 3695 1 :AutoInstall: commentary.vim

if exists("g:loaded_commentary") || &cp || v:version < 700
  finish
endif
let g:loaded_commentary = 1

function! s:surroundings() abort
  return split(substitute(substitute(
        \ get(b:, 'commentary_format', &commentstring)
        \ ,'\S\zs%s','%s','') ,'%s\ze\S', '%s', ''), '%s', 1)
endfunction

function! s:go(type,...) abort
  if a:0
    let [lnum1, lnum2] = [a:type, a:1]
  else
    let [lnum1, lnum2] = [line("'["), line("']")]
  endif

  let [l, r] = s:surroundings()
  let uncomment = 2
  for lnum in range(lnum1,lnum2)
    let line = matchstr(getline(lnum),'\S.*\s\@<!')
    if line != '' && (stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
      let uncomment = 0
    endif
  endfor

  if strlen(r) > 1 && l.r !~# '\\'
    let mult = 1
  else
    let mult = 0
    let l = l.' '
    if strlen(r) | let r = ' '.r | endif
  endif

  for lnum in range(lnum1,lnum2)
    let line = getline(lnum)
    if mult
      if uncomment
        let line = substitute(line,
            \'\M\( \)\('.l[0].'\)\(\d\*\)\('.l[1:-1].'\) ',
            \'\=submatch(2).substitute(submatch(3)+1-uncomment,"^0$\\|^-\\d*$","","").submatch(4)','g')
        let line = substitute(line,
            \'\M\( \)\('.r[0:-2].'\)\(\d\*\)\('.r[-1:-1].'\) ',
            \'\=submatch(2).substitute(submatch(3)+1-uncomment,"^0$\\|^-\\d*$","","").submatch(4)','g')
      else
        let line = substitute(line,
            \'\M\('.l[0].'\)\(\d\*\)\('.l[1:-1].'\)',
            \'\=" ".submatch(1).substitute(submatch(2)+1-uncomment,"^0$\\|^-\\d*$","","").submatch(3)." "','g')
        let line = substitute(line,
            \'\M\('.r[0:-2].'\)\(\d\*\)\('.r[-1:-1].'\)',
            \'\=" ".submatch(1).substitute(submatch(2)+1-uncomment,"^0$\\|^-\\d*$","","").submatch(3)." "','g')
      endif
    endif
    if uncomment
      let line = substitute(line,'\S.*\s\@<!','\=submatch(0)[strlen(l):-strlen(r)-1]','')
    else
      let line = substitute(line,'^\%('.matchstr(getline(lnum1),'^\s*').'\|\s*\)\zs.*\S\@<=','\=l.submatch(0).r','')
      let line = substitute(line, '\M\('.l[0].'\d\+'.l[1:-1].'\|'.r[0:-2].'\d\+'.r[-1:-1].'\) \@!', '& ','g')
    endif
    call setline(lnum,line)
  endfor
  let modelines = &modelines
  try
    set modelines=0
    silent doautocmd User CommentaryPost
  finally
    let &modelines = modelines
  endtry
endfunction

function! s:textobject(inner) abort
  let [l, r] = s:surroundings()
  let lnums = [line('.')+1, line('.')-2]
  for [index, dir, bound, line] in [[0, -1, 1, ''], [1, 1, line('$'), '']]
    while lnums[index] != bound && line ==# '' || !(stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
      let lnums[index] += dir
      let line = matchstr(getline(lnums[index]+dir),'\S.*\s\@<!')
    endwhile
  endfor
  while (a:inner || lnums[1] != line('$')) && empty(getline(lnums[0]))
    let lnums[0] += 1
  endwhile
  while a:inner && empty(getline(lnums[1]))
    let lnums[1] -= 1
  endwhile
  if lnums[0] <= lnums[1]
    execute 'normal! 'lnums[0].'GV'.lnums[1].'G'
  endif
endfunction

xnoremap <silent> <Plug>Commentary     :<C-U>call <SID>go(line("'<"),line("'>"))<CR>
nnoremap <silent> <Plug>Commentary     :<C-U>set opfunc=<SID>go<CR>g@
nnoremap <silent> <Plug>CommentaryLine :<C-U>set opfunc=<SID>go<Bar>exe 'norm! 'v:count1.'g@_'<CR>
onoremap <silent> <Plug>Commentary        :<C-U>call <SID>textobject(0)<CR>
nnoremap <silent> <Plug>ChangeCommentary c:<C-U>call <SID>textobject(1)<CR>
nmap <silent> <Plug>CommentaryUndo <Plug>Commentary<Plug>Commentary

if 1 || !hasmapto('<Plug>Commentary') || maparg('gc','n') ==# ''
  xmap gc  <Plug>Commentary
  nmap gc  <Plug>Commentary
  omap gc  <Plug>Commentary
  nmap gcc <Plug>CommentaryLine
  nmap cgc <Plug>ChangeCommentary
  nmap gcu <Plug>Commentary<Plug>Commentary
endif

if maparg('\\','n') ==# '' && maparg('\','n') ==# '' && get(g:, 'commentary_map_backslash', 1)
  xmap \\  <Plug>Commentary:echomsg '\\ is deprecated. Use gc'<CR>
  nmap \\  :echomsg '\\ is deprecated. Use gc'<CR><Plug>Commentary
  nmap \\\ <Plug>CommentaryLine:echomsg '\\ is deprecated. Use gc'<CR>
  nmap \\u <Plug>CommentaryUndo:echomsg '\\ is deprecated. Use gc'<CR>
endif

" vim:set et sw=2:

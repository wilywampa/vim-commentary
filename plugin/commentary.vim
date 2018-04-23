" commentary.vim - Comment stuff out
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      wilywampa's fork
" GetLatestVimScripts: 3695 1 :AutoInstall: commentary.vim

if exists("g:loaded_commentary") || v:version < 700
  finish
endif
let g:loaded_commentary = 1

function! s:surroundings() abort
  return split(substitute(substitute(
        \ get(b:, 'commentary_format', &commentstring)
        \ ,'\S\zs%s','%s','') ,'%s\ze\S', '%s', ''), '%s', 1)
endfunction

function! s:strip_white_space(l,r,line) abort
  let [l, r] = [a:l, a:r]
  if l[-1:] ==# ' ' && stridx(a:line,l) == -1 && stridx(a:line,l[0:-2]) == 0
    let l = l[:-2]
  endif
  if r[0] ==# ' ' && a:line[-strlen(r):] != r && a:line[1-strlen(r):] == r[1:]
    let r = r[1:]
  endif
  return [l, r]
endfunction

function! s:go(...) abort
  if !a:0
    let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
    return 'g@'
  elseif a:0 > 1
    let [lnum1, lnum2] = [a:1, a:2]
  else
    let [lnum1, lnum2] = [line("'["), line("']")]
  endif

  while lnum1 < lnum2 && getline(lnum1) !~ '\S'
    let lnum1 = lnum1 + 1
  endwhile

  let [l, r] = s:surroundings()
  let uncomment = 2
  for lnum in range(lnum1,lnum2)
    let line = matchstr(getline(lnum),'\S.*\s\@<!')
    let [l, r] = s:strip_white_space(l,r,line)
    if len(line) && (stridx(line,l.' ') || (strlen(r) && line[strlen(line)-strlen(' '.r) : -1] != ' '.r))
      let uncomment = 0
    endif
  endfor

  if exists('s:com') && uncomment
    return
  endif

  let mult = strlen(r) > 1 && l.r !~# '\\'
  if !mult
    let l = l.' '
    if strlen(r) | let r = ' '.r | endif
  endif

  for lnum in filter(range(lnum1, lnum2), 'nextnonblank(v:val) == v:val')
    if !exists('min_indent') || indent(lnum) < min_indent
      let min_indent = indent(lnum)
      let indent = matchstr(getline(lnum), '^\s*')
    endif
  endfor
  if !exists('indent') | let indent = '' | endif

  for lnum in range(lnum1,lnum2)
    let line = getline(lnum)
    if line =~ '\S'
      if mult
        if uncomment
          let line = substitute(line,
              \'\M\( \)\('.l[0].'\)\(\d\+\)\('.l[1:-1].'\) ',
              \'\=submatch(2).substitute(submatch(3)+1-uncomment,"^0$\\|^-\\d*$","","").submatch(4)','g')
          let line = substitute(line,
              \'\M\( \)\('.r[0:-2].'\)\(\d\+\)\('.r[-1:-1].'\) ',
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
        let line = substitute(line,'\S.*\s\@<!','\=submatch(0)[(strlen(l)+mult):-strlen(r)-1-mult]','')
      else
        let line = substitute(line,'^\%('.indent.'\|\s*\)\zs.\+','\=l.(mult?" ":"").submatch(0).(mult?" ":"").r','')
        if mult
          let line = substitute(line,'\M\('.l[0].'\d\+'.l[1:-1].'\|'.r[0:-2].'\d\+'.r[-1:-1].'\) \@!', '& ','g')
          let line = substitute(line,'\M \@<!'.r,' &','')
        endif
      endif
      call setline(lnum,line)
    endif
  endfor
  let modelines = &modelines
  try
    set modelines=0
    silent doautocmd User CommentaryPost
  finally
    let &modelines = modelines
  endtry
  return ''
endfunction

function! s:textobject(inner) abort
  let [l, r] = s:surroundings()
  let lnums = [line('.')+1, line('.')-2]
  for [index, dir, bound, line] in [[0, -1, 1, ''], [1, 1, line('$'), '']]
    while lnums[index] != bound && line ==# '' || !(stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
      let lnums[index] += dir
      let line = matchstr(getline(lnums[index]+dir),'\S.*\s\@<!')
      let [l, r] = s:strip_white_space(l,r,line)
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

func! s:com()
  if exists('s:com')
    unlet s:com
  else
    let s:com = 1
  endif
endfunc

func! s:com()
  if exists('s:com')
    unlet s:com
  else
    let s:com = 1
  endif
endfunc

command! -range -bar Commentary call s:go(<line1>,<line2>)
xnoremap <silent> <Plug>Commentary     :Commentary<CR>
nnoremap <expr>   <Plug>Commentary     <SID>go()
nnoremap <expr>   <Plug>CommentaryLine <SID>go() . '_'
onoremap <silent> <Plug>Commentary        :<C-U>call <SID>textobject(0)<CR>
nnoremap <silent> <Plug>ChangeCommentary c:<C-U>call <SID>textobject(1)<CR>
nmap <silent> <Plug>CommentaryUndo :echoerr "Change your <Plug>CommentaryUndo map to <Plug>Commentary<Plug>Commentary"<CR>

if !hasmapto('<Plug>Commentary') || maparg('gc','n') ==# ''
  xmap gc  <Plug>Commentary
  nmap gc  <Plug>Commentary
  omap gc  <Plug>Commentary
  nmap gcc <Plug>CommentaryLine
  if maparg('c','n') ==# ''
    nmap cgc <Plug>ChangeCommentary
  endif
  nmap gcu <Plug>Commentary<Plug>Commentary
  nmap gco <Plug>CommentLine
endif

" vim:set et sw=2:

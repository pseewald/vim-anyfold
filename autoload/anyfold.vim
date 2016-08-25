" AnyFold plugin

"----------------------------------------------------------------------------/
" Activation of requested features
"----------------------------------------------------------------------------/
function anyfold#init(nindent, comment_char)

    if !exists('g:_ANYFOLD_DEFAULTS')
        let g:_ANYFOLD_DEFAULTS = {
                    \ 'lang_settings':                      1,
                    \ 'nindent':                    a:nindent,
                    \ 'equalprg':                          '',
                    \ 'equalprg_args':                     '',
                    \ 'docu_fold':                          0,
                    \ 'fold_display':                       1,
                    \ 'fold_motion':                        1,
                    \ 'toggle_key':                 '<space>',
                    \ 'reload_key':                    '<F5>',
                    \ 'debug':                              0,
                    \ }
       lockvar g:_ANYFOLD_DEFAULTS
    endif

    for s:key in keys(g:_ANYFOLD_DEFAULTS)
        if !exists('g:anyfold_' . s:key)
            let g:anyfold_{s:key} = copy(g:_ANYFOLD_DEFAULTS[s:key])
        endif
    endfor

    if executable(g:anyfold_equalprg)
        exe 'setlocal equalprg='.fnameescape(g:anyfold_equalprg.' '.g:anyfold_equalprg_args)
        " need to do some cleanup work in case equalprg fails
        " vim has a really bad default solution here (replace text to be
        " formatted by error message)
        autocmd ShellFilterPost * :call s:PostEqualprg()
    endif

    if g:anyfold_lang_settings
        call s:SetGenLangSettings()
    endif

    let s:comment_char = a:comment_char
    let b:anyfold_indent_list = s:GetIndentList()
    lockvar! b:anyfold_indent_list
    let b:anyfold_doculines = s:GetDocuBoxes()
    lockvar! b:anyfold_doculines

    setlocal foldmethod=expr
    setlocal foldexpr=GetIndentFold(v:lnum)

    if g:anyfold_fold_display
        setlocal foldtext=MinimalFoldText()
    endif

    exe 'noremap <script> <buffer> <silent>' g:anyfold_toggle_key
                    \' :call <SID>ToggleFolds()<cr>'

    exe 'noremap <script> <buffer> <silent>' g:anyfold_reload_key
                    \' :call <SID>ReloadBuffer()<cr>'

    if g:anyfold_fold_motion
        noremap <script> <buffer> <silent> ]]
                    \ :call <SID>JumpFoldEnd(0)<cr>

        noremap <script> <buffer> <silent> [[
                    \ :call <SID>JumpFoldStart(0)<cr>

        noremap <script> <buffer> <silent> ]k
                    \ :call <SID>JumpPrevFoldEnd(0)<cr>

        noremap <script> <buffer> <silent> [j
                    \ :call <SID>JumpNextFoldStart(0)<cr>

        vnoremap <script> <buffer> <silent> ]]
                    \ :<c-u>call <SID>JumpFoldEnd(1)<cr>

        vnoremap <script> <buffer> <silent> [[
                    \ :<c-u>call <SID>JumpFoldStart(1)<cr>

        vnoremap <script> <buffer> <silent> ]k
                    \ :<c-u>call <SID>JumpPrevFoldEnd(1)<cr>

        vnoremap <script> <buffer> <silent> [j
                    \ :<c-u>call <SID>JumpNextFoldStart(1)<cr>
    endif

    if g:anyfold_debug
        noremap <script> <buffer> <silent> <F11>
                    \ :call <SID>echoLineIndent()<cr>
    endif

    if g:anyfold_debug
        noremap <script> <buffer> <silent> <F12>
                    \ :call <SID>echoBox()<cr>
    endif
endfunction

"----------------------------------------------------------------------------/
" Setting indentation width
"----------------------------------------------------------------------------/
function! s:SetGenLangSettings()
    exe 'setlocal shiftwidth='.g:anyfold_nindent
    exe 'setlocal tabstop='.g:anyfold_nindent
    exe 'setlocal softtabstop='.g:anyfold_nindent
    setlocal expandtab
endfunction

"----------------------------------------------------------------------------/
" Cleanup incase equalprg failed
"----------------------------------------------------------------------------/
function! s:PostEqualprg()
   if v:shell_error == 1
       silent normal! u
       echoerr 'external equalprg failed with an error'
   endif
endfunction

"----------------------------------------------------------------------------/
" Folding
"----------------------------------------------------------------------------/
function! s:NextNonBlankLine(lnum)
    let numlines = line('$')
    let current = a:lnum + 1

    while current <= numlines
        if getline(current) =~? '\v\S' && getline(current) !~? '\v^['.s:comment_char.'#]'
            return current
        endif

        let current += 1
    endwhile

    return -1
endfunction

function! s:PrevNonBlankLine(lnum)
    let current = a:lnum - 1

    while current > 0
        if getline(current) =~? '\v\S' && getline(current) !~? '\v^['.s:comment_char.'#]'
            return current
        endif

        let current += -1
    endwhile

    return 0
endfunction

" get indent hierarchy from actual indents
function! s:GetIndentList()

    " get list of actual indents (ind_list)
    let numlines = line('$')
    let ind_list = [0]
    let current = 0
    while current <= numlines
        let prev_indent = indent(s:PrevNonBlankLine(current))
        let next_indent = indent(s:NextNonBlankLine(current))
        if getline(current) =~? '\v\S' && getline(current) !~? '\v^['.s:comment_char.'#]'
            let ind_list += [indent(current)]
        else
            let ind_list += [max([prev_indent,next_indent])]
        endif
        let current += 1
    endwhile
    let ind_list = ind_list[1:]

    " get hierarchical list of indents (hierind_list)
    let prev_ind = ind_list[-1]
    let hierind_list = [0]
    let ind_open_list = [0]
    for ind in ind_list
        if ind > prev_ind
            let hierind_list += [hierind_list[-1] + 1]
            let ind_open_list += [ind]
        elseif ind == prev_ind
            let hierind_list += [hierind_list[-1]]
            if ind_open_list[-1] < ind
                let ind_open_list += [ind]
            elseif ind_open_list[-1] > ind
                let ind_open_list[-1] = ind
            endif
        elseif ind < prev_ind
            let n_closed = 0
            while ind < ind_open_list[-1] && ind <= ind_open_list[-2]
                let ind_open_list = ind_open_list[:-2]
                let n_closed += 1
            endwhile
            let hierind_list += [hierind_list[-1]-n_closed]
        endif
        let prev_ind = ind
    endfor
    let hierind_list = hierind_list[1:]

    return hierind_list
endfunction

function! s:GetDocuBoxes()
    let numlines = line('$')
    let doculines=[]
    let current=0
    let inbox =0

    while current <= numlines
        let doculines += [0]
        if exists("b:anyfold_docubox_mark")
            if !empty(matchstr(getline(current),'^\s*'.b:anyfold_docubox_mark))
                let doculines[-1] = 1
            endif
        elseif exists("b:anyfold_docubox_start") && exists("b:anyfold_docubox_end")
            if !inbox
                if !empty(matchstr(getline(current),'^\s*'.b:anyfold_docubox_start))
                    let doculines[-1] = 1
                    let inbox=1
                endif
            else
                let doculines[-1] = 1
                if !empty(matchstr(getline(current),'^\s*'.b:anyfold_docubox_end))
                    let inbox=0
                endif
            endif
        endif
        let current += 1
    endwhile

    return doculines
endfunction

function! GetIndentFold(lnum)

    if b:anyfold_doculines[a:lnum]
        if g:anyfold_docu_fold
            return b:anyfold_indent_list[a:lnum] + 1
        else
            return -1
        endif
    endif

    let this_indent = b:anyfold_indent_list[a:lnum]

    if a:lnum == len(b:anyfold_indent_list)-1
        return this_indent
    endif

    let next_indent = b:anyfold_indent_list[a:lnum+1]
    if next_indent <= this_indent
        return this_indent
    else
        return '>' . next_indent
    endif

endfunction

function! s:ToggleFolds()
   if foldclosed(line('.')) != -1
       normal zO
   else
       normal zc
   endif
endfunction

function! s:ReloadBuffer()
    let l:winview = winsaveview()
    bdelete | edit # | normal zv
    call winrestview(l:winview)
endfunction

function! s:echoLineIndent()
    echo GetIndentFold(line('.'))
endfunction

function! s:echoBox()
    echo b:anyfold_doculines[line('.')]
endfunction

"----------------------------------------------------------------------------/
" Improved fold display
" Inspired by example code by Greg Sexton
" http://www.gregsexton.org/2011/03/improving-the-text-displayed-in-a-fold/
"----------------------------------------------------------------------------/
function! MinimalFoldText()
    let fs = v:foldstart
    while getline(fs) =~ '^\s*$' | let fs = nextnonblank(fs + 1)
    endwhile
    let line = getline(v:foldstart)
    let w = winwidth(0) - &foldcolumn - (&number ? 8 : 0)
    let foldSize = 1 + v:foldend - v:foldstart
    let foldSizeStr = " " . foldSize . " lines "
    let foldLevelStr = repeat("  +  ", v:foldlevel)
    let lineCount = line("$")
    let expansionString = "   " . repeat(" ", w - strwidth(foldSizeStr.line.foldLevelStr) -3)
    return line . expansionString . foldSizeStr . foldLevelStr
endfunction

"----------------------------------------------------------------------------/
" Motion
"----------------------------------------------------------------------------/
function! s:JumpFoldStart(visual)
    if a:visual
        normal! gv
    endif
    if b:anyfold_indent_list[line('.')-1] < b:anyfold_indent_list[line('.')]
        normal! j
    endif
    let curr_ind = b:anyfold_indent_list[line('.')]
    normal! k[z0
    while b:anyfold_indent_list[line('.')] > curr_ind
        normal! [z0
    endwhile
endfunction

function! s:JumpFoldEnd(visual)
    if a:visual
        normal! gv
    endif
    if b:anyfold_indent_list[line('.')+1] < b:anyfold_indent_list[line('.')]
        normal! k
    endif
    let curr_ind = b:anyfold_indent_list[line('.')]
    normal! ]zj0
    while b:anyfold_indent_list[line('.')] > curr_ind
        normal! ]zj0
    endwhile
endfunction

function! s:JumpPrevFoldEnd(visual)
    if a:visual
        normal! gv
    endif
    normal! kzkj
endfunction

function! s:JumpNextFoldStart(visual)
    if a:visual
        normal! gv
    endif
    normal! zj
endfunction
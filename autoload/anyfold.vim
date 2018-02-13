function! anyfold#reset() abort
    if exists("b:anyfold_initialised")
        unlet b:anyfold_initialised
    endif
endfunction
"----------------------------------------------------------------------------/
" Initialization: Activation of requested features
"----------------------------------------------------------------------------/
function! anyfold#init() abort

    if exists("g:anyfold_activate")
        let b:anyfold_activate = g:anyfold_activate
    endif

    if !exists("b:anyfold_activate")
        return
    elseif !b:anyfold_activate
        return
    endif

    " make sure initialisation only happens once
    if exists("b:anyfold_initialised")
        return
    else
        let b:anyfold_initialised = 1
    endif

    let b:anyfold_disable = &diff || (&buftype ==# "terminal")
    if b:anyfold_disable
        return
    endif

    " Options and defaults
    if !exists('g:_ANYFOLD_DEFAULTS')
        let g:_ANYFOLD_DEFAULTS = {
                    \ 'identify_comments':            1,
                    \ 'fold_comments':                0,
                    \ 'fold_toplevel':                0,
                    \ 'fold_display':                 1,
                    \ 'motion':                       1,
                    \ 'debug':                        0,
                    \ }
        lockvar! g:_ANYFOLD_DEFAULTS
    endif

    for s:key in keys(g:_ANYFOLD_DEFAULTS)
        if !exists('g:anyfold_' . s:key)
            let g:anyfold_{s:key} = copy(g:_ANYFOLD_DEFAULTS[s:key])
        endif
    endfor

    " Option dependencies
    if g:anyfold_fold_comments
        let g:anyfold_identify_comments = max([1, g:anyfold_identify_comments])
    endif

    " Create list with indents / foldlevels
    call s:InitIndentList()

    " Set folds
    setlocal foldmethod=expr
    setlocal foldexpr=b:anyfold_ind_buffer[v:lnum-1]

    " Fold display
    if g:anyfold_fold_display
        setlocal foldtext=MinimalFoldText()
    endif

    " folds are always updated when buffer has changed
    autocmd TextChanged,InsertLeave <buffer> :call s:ReloadFolds()

    if g:anyfold_motion
        noremap <script> <buffer> <silent> ]]
                    \ :<c-u>call <SID>JumpFoldEnd(0,v:count1)<cr>

        noremap <script> <buffer> <silent> [[
                    \ :<c-u>call <SID>JumpFoldStart(0,v:count1)<cr>

        noremap <script> <buffer> <silent> ]k
                    \ :<c-u>call <SID>JumpPrevFoldEnd(0,v:count1)<cr>

        noremap <script> <buffer> <silent> [j
                    \ :<c-u>call <SID>JumpNextFoldStart(0,v:count1)<cr>

        vnoremap <script> <buffer> <silent> ]]
                    \ :<c-u>call <SID>JumpFoldEnd(1,v:count1)<cr>

        vnoremap <script> <buffer> <silent> [[
                    \ :<c-u>call <SID>JumpFoldStart(1,v:count1)<cr>

        vnoremap <script> <buffer> <silent> ]k
                    \ :<c-u>call <SID>JumpPrevFoldEnd(1,v:count1)<cr>

        vnoremap <script> <buffer> <silent> [j
                    \ :<c-u>call <SID>JumpNextFoldStart(1,v:count1)<cr>
    endif

    " mappings for debugging
    if g:anyfold_debug
        noremap <script> <buffer> <silent> <F10>
                    \ :call <SID>EchoIndents(1)<cr>
        noremap <script> <buffer> <silent> <F11>
                    \ :call <SID>EchoIndents(2)<cr>
        noremap <script> <buffer> <silent> <F12>
                    \ :call <SID>EchoIndents(3)<cr>
    endif

    silent doautocmd User anyfoldLoaded
endfunction

"----------------------------------------------------------------------------/
" Identify comment lines
"----------------------------------------------------------------------------/
function! s:MarkCommentLines(line_start, line_end, force) abort
    let commentlines = []
    let curr_line = a:line_start
    while curr_line <= a:line_end
        " here we force identification of a comment line if it may belong to a
        " multiline comment (in this case we can not assume that it is
        " unindented)
        let force = a:force
        if force == 0
            if curr_line > a:line_start
                let force = commentlines[-1]
            else
                let force = 1
            endif
        endif
        let commentlines += [0]
        if s:CommentLine(curr_line, force)
            let commentlines[-1] = 1
        endif
        let curr_line += 1
    endwhile
    return commentlines
endfunction

"----------------------------------------------------------------------------/
" Check if line is unindented comment or preprocessor statement
" Note: synID is very slow, therefore we identify unindented comments only
" (or if force==1)
"----------------------------------------------------------------------------/
function! s:CommentLine(lnum, force) abort
    if indent(a:lnum) >= &sw && !a:force
        return 0
    else
        return synIDattr(synID(a:lnum,indent(a:lnum)+1,1),"name") =~? 'comment\|string'
                    \ || getline(a:lnum)[0] == '#'
    endif
endfunction

"----------------------------------------------------------------------------/
" Utility function to check if line is comment
"----------------------------------------------------------------------------/
function! s:IsComment(lnum) abort
    if g:anyfold_identify_comments
        if a:lnum <= line('$') && a:lnum > 0
            return b:anyfold_commentlines[a:lnum-1]
        else
            return 0
        endif
    else
        return 0
    endif
endfunction

"----------------------------------------------------------------------------/
" Utility function to check if line is to be considered
" Note: this implements good heuristics for braces
"----------------------------------------------------------------------------/
function! s:ConsiderLine(lnum) abort
    if getline(a:lnum) !~? '\v\S'
        " empty line
        return 0
    elseif getline(a:lnum) =~? '^\s*\W\s*$'
        " line containing brace only
        return 0
    elseif s:IsComment(a:lnum)
        " unindented comment line
        return 0
    else
        return 1
    endif
endfunction

"----------------------------------------------------------------------------/
" Next non-blank line
"----------------------------------------------------------------------------/
function! s:NextNonBlankLine(lnum) abort
    let numlines = line('$')
    let curr_line = a:lnum + 1

    while curr_line <= numlines
        if s:ConsiderLine(curr_line)
            return curr_line
        endif

        let curr_line += 1
    endwhile

    return -1
endfunction

"----------------------------------------------------------------------------/
" Previous non-blank line
"----------------------------------------------------------------------------/
function! s:PrevNonBlankLine(lnum) abort
    let curr_line = a:lnum - 1

    while curr_line > 0
        if s:ConsiderLine(curr_line)
            return curr_line
        endif

        let curr_line += -1
    endwhile

    return 0
endfunction

function! s:InitIndentList() abort

    if g:anyfold_identify_comments
        let force = g:anyfold_identify_comments == 2
        unlockvar! b:anyfold_commentlines
        let b:anyfold_commentlines = s:MarkCommentLines(1, line('$'), force)
        lockvar! b:anyfold_commentlines
    endif

    unlockvar! b:anyfold_ind_actual
    let b:anyfold_ind_actual = s:ActualIndents(1, line('$'))
    unlockvar! b:anyfold_ind_contextual
    let b:anyfold_ind_contextual = s:ContextualIndents(0, 1, line('$'), b:anyfold_ind_actual)
    unlockvar! b:anyfold_ind_buffer
    let b:anyfold_ind_buffer = s:BufferIndents(1, line('$'))

    lockvar! b:anyfold_ind_buffer
    lockvar! b:anyfold_ind_actual
    lockvar! b:anyfold_ind_contextual
endfunction

"----------------------------------------------------------------------------/
" get actual indents
" don't depend on context
"----------------------------------------------------------------------------/
function! s:ActualIndents(line_start, line_end) abort
    let ind_list = []
    let curr_line = a:line_start
    while curr_line <= a:line_end
        let ind_list += [s:LineIndent(curr_line)]
        let curr_line += 1
    endwhile
    return ind_list
endfunction

"----------------------------------------------------------------------------/
" get indent, filtering ignores special lines (empty lines, comment lines ...)
"----------------------------------------------------------------------------/
function! s:LineIndent(lnum) abort
    let prev_indent = indent(s:PrevNonBlankLine(a:lnum))
    let next_indent = indent(s:NextNonBlankLine(a:lnum))
    if s:ConsiderLine(a:lnum)
        return indent(a:lnum)
    else
        return max([prev_indent,next_indent])
    endif
endfunction

"----------------------------------------------------------------------------/
" buffer for indents used in foldexpr
"----------------------------------------------------------------------------/
function! s:BufferIndents(line_start, line_end) abort
    let ind_list = []
    let curr_line = a:line_start
    while curr_line <= a:line_end
        let ind_list += [s:GetIndentFold(curr_line)]
        let curr_line += 1
    endwhile
    return ind_list
endfunction

"----------------------------------------------------------------------------/
" get indent hierarchy from actual indents
" indents depend on context
"----------------------------------------------------------------------------/
function! s:ContextualIndents(init_ind, line_start, line_end, ind_list) abort
    let prev_ind = a:ind_list[0]
    let hierind_list = [a:init_ind]
    let ind_open_list = [a:ind_list[0]]

    for ind in a:ind_list
        if ind > prev_ind
            " this line starts a new block
            let hierind_list += [hierind_list[-1] + 1]
            let ind_open_list += [ind]
        elseif ind == prev_ind
            " this line continues a block
            let hierind_list += [hierind_list[-1]]
        elseif ind < prev_ind
            " this line closes current block only if indent is less or equal to
            " indent of the line starting the block (=ind_open_list[-2])
            " line may close more than one block
            let n_closed = 0
            while len(ind_open_list) >= 2 && ind <= ind_open_list[-2]
                " close block
                let ind_open_list = ind_open_list[:-2]
                let n_closed += 1
            endwhile

            " update current block indent
            let ind_open_list[-1] = ind

            let hierind_list += [hierind_list[-1]-n_closed]
        endif
        let prev_ind = ind
    endfor
    let hierind_list = hierind_list[1:]
    return hierind_list
endfunction

"----------------------------------------------------------------------------/
" fold expression
"----------------------------------------------------------------------------/
function! s:GetIndentFold(lnum) abort
    if s:IsComment(a:lnum) && (s:IsComment(a:lnum-1) || s:IsComment(a:lnum+1))
        if g:anyfold_fold_comments
            " introduce artifical fold for docuboxes
            return b:anyfold_ind_contextual[a:lnum-1] + 1
        endif
    endif

    let this_indent = b:anyfold_ind_contextual[a:lnum-1]

    if a:lnum >= line('$')
        let next_indent = 0
    else
        let next_indent = b:anyfold_ind_contextual[a:lnum]
    endif

    " heuristics to define blocks at foldlevel 0
    if g:anyfold_fold_toplevel && this_indent == 0

        let prev_indent = b:anyfold_ind_contextual[a:lnum-2]

        if a:lnum == 1
            let prevprev_indent = 0
        else
            let prevprev_indent = b:anyfold_ind_contextual[a:lnum-3]
        endif

        if a:lnum >= line('$') - 1
            let nextnext_indent = 0
        else
            let nextnext_indent = b:anyfold_ind_contextual[a:lnum+1]
        endif

        if next_indent > 0
            return '>1'
        endif

        if prev_indent > 0
            return 0
        else
            if prevprev_indent > 0
                if next_indent == 0 && nextnext_indent == 0
                    return '>1'
                else
                    return 0
                endif
            else
                return 1
            endif
        endif
    endif

    if next_indent <= this_indent
        return this_indent
    else
        return '>' . next_indent
    endif

endfunction

"----------------------------------------------------------------------------/
" Update folds
" Only lines that have been changed are updated
"----------------------------------------------------------------------------/
function! s:ReloadFolds() abort

    " many of the precautions taken are necessary because the marks of
    " previously changed text '[ & '] are not always reliable, for instance if
    " text is inserted by a script. There may be vim bugs such as
    " vim/vim#1281.

    let changed_start = min([getpos("'[")[1], line('$')])
    let changed_end = min([getpos("']")[1], line('$')])

    let changed_tmp = [changed_start, changed_end]
    let changed = [min(changed_tmp), max(changed_tmp)]

    let changed_lines = changed[1] - changed[0] + 1
    let delta_lines = line('$') - len(b:anyfold_ind_actual)

    " if number of changed lines smaller than number of added / removed lines,
    " something went wrong and we mark all lines as changed.
    if changed_lines < delta_lines
        let changed[0] = 1
        let changed[1] = line('$')
        let changed_lines = changed[1] - changed[0] + 1
    endif

    " partially update comments
    if g:anyfold_identify_comments
        let force = g:anyfold_identify_comments == 2
        unlockvar! b:anyfold_commentlines
        let b:anyfold_commentlines = s:ExtendLineList(b:anyfold_commentlines, changed[0], changed[1])
        if changed_lines > 0
            let b:anyfold_commentlines[changed[0]-1 : changed[1]-1] = s:MarkCommentLines(changed[0], changed[1], force)
        endif
        lockvar! b:anyfold_commentlines
    endif

    " if number of lines has not changed and indents are the same, skip update
    if delta_lines == 0
        let indents_same = 1
        let curr_line = changed[0]
        while curr_line <= changed[1]
            if s:LineIndent(curr_line) != b:anyfold_ind_actual[curr_line - 1]
                let indents_same = 0
                break
            endif
            let curr_line += 1
        endwhile
        if indents_same
            return
        endif
    endif

    " get first and last line of previously changed block
    let changed[0] = s:PrevNonBlankLine(changed[0])
    let changed[1] = s:NextNonBlankLine(changed[1])
    if changed[0] == 0
        let changed[0] = 1
    endif
    if changed[1] == -1
        let changed[1] = line('$')
    endif
    let changed_lines = changed[1] - changed[0] + 1

    unlockvar! b:anyfold_ind_actual
    unlockvar! b:anyfold_ind_contextual
    unlockvar! b:anyfold_ind_buffer

    let b:anyfold_ind_actual = s:ExtendLineList(b:anyfold_ind_actual, changed[0], changed[1])
    let b:anyfold_ind_contextual = s:ExtendLineList(b:anyfold_ind_contextual, changed[0], changed[1])
    let b:anyfold_ind_buffer = s:ExtendLineList(b:anyfold_ind_buffer, changed[0], changed[1])

    if changed_lines > 0

        " partially update actual indent
        let b:anyfold_ind_actual[changed[0]-1 : changed[1]-1] = s:ActualIndents(changed[0], changed[1])

        " find end of current code block for updating contextual indents
        " 1) find minimal indent present in changed block
        " 2) move down until line is found with indent <= minimal indent of
        " changed block
        let min_indent = min(b:anyfold_ind_actual[changed[0]-1 : changed[1]-1])

        " subtract one to make sure that new indent is applied to all lines of the
        " current block
        let min_indent = max([min_indent-1, 0])

        " find end of current block for updating contextual indents
        let curr_line = changed[1]
        let block_start_found = 0
        while !block_start_found
            if curr_line < line('$')
                let curr_line += 1
            endif
            if b:anyfold_ind_actual[curr_line-1] <= min_indent
                let block_start_found = 1
            endif

            if curr_line == line('$') && !block_start_found
                let block_start_found = 1
            endif
        endwhile
        let changed_block_end = curr_line

        " find beginning of current block, now minimal indent is indent of
        " last line of block
        let min_indent = min([b:anyfold_ind_actual[curr_line-1], min_indent])

        let curr_line = changed[0]
        let block_start_found = 0
        while !block_start_found
            if curr_line > 1
                let curr_line += -1
            endif
            if b:anyfold_ind_actual[curr_line-1] <= min_indent
                let block_start_found = 1
            endif

            if curr_line == 1 && !block_start_found
                let block_start_found = 1
            endif
        endwhile
        let changed_block_start = curr_line

        let changed_block = [changed_block_start, changed_block_end]

        let init_ind = b:anyfold_ind_contextual[changed_block[0]-1]
        let b:anyfold_ind_contextual[changed_block[0]-1 : changed_block[1]-1] =
                    \ s:ContextualIndents(init_ind, changed_block[0], changed_block[1],
                    \ b:anyfold_ind_actual[changed_block[0]-1:changed_block[1]-1])

        let b:anyfold_ind_buffer[changed_block[0]-1 : changed_block[1]-1] = s:BufferIndents(changed_block[0], changed_block[1])
    endif

    lockvar! b:anyfold_ind_actual
    lockvar! b:anyfold_ind_contextual
    lockvar! b:anyfold_ind_buffer

    setlocal foldexpr=b:anyfold_ind_buffer[v:lnum-1]

endfunction

"----------------------------------------------------------------------------/
" Extend lists containing entries for each line to the current number of lines.
" Zero out part that correspond to changed lines and move all other entries to
" the correct positions.
"----------------------------------------------------------------------------/
function! s:ExtendLineList(list, insert_start, insert_end) abort
    let nchanged = a:insert_end - a:insert_start + 1
    let delta_lines = line('$') - len(a:list)

    let b1 = a:insert_start-2
    let b2 = a:insert_end-delta_lines

    let push_front = b1 >= 0
    let push_back = b2 <= len(a:list) - 1

    if push_front && push_back
        return a:list[ : b1] + repeat([0], nchanged) + a:list[b2 : ]
    elseif push_front
        return a:list[ : b1] + repeat([0], nchanged)
    elseif push_back
        return repeat([0], nchanged) + a:list[b2 : ]
    else
        return repeat([0], nchanged)
    endif

endfunction

"----------------------------------------------------------------------------/
" Improved fold display
" Inspired by example code by Greg Sexton
" http://www.gregsexton.org/2011/03/improving-the-text-displayed-in-a-fold/
"----------------------------------------------------------------------------/
function! MinimalFoldText() abort
    let fs = v:foldstart
    while getline(fs) !~ '\w'
        let fs = nextnonblank(fs + 1)
    endwhile
    if fs > v:foldend
        let line = getline(v:foldstart)
    else
        let line = substitute(getline(fs), '\t', repeat(' ', &tabstop), 'g')
    endif

    let w = winwidth(0) - &foldcolumn - &number * &numberwidth
    let foldSize = 1 + v:foldend - v:foldstart
    let foldSizeStr = " " . foldSize . " lines "
    let foldLevelStr = repeat("  +  ", v:foldlevel)
    let lineCount = line("$")
    let expansionString = repeat(" ", w - strwidth(foldSizeStr.line.foldLevelStr))
    return line . expansionString . foldSizeStr . foldLevelStr
endfunction

"----------------------------------------------------------------------------/
" Motion
"----------------------------------------------------------------------------/
function! s:JumpFoldStart(visual, count1) abort
    if a:visual
        normal! gv
    endif

    let curr_line = line('.')
    let rep=0
    while rep < a:count1
        let rep += 1
        if curr_line == 1
            call cursor(1,1)
            return
        endif

        let curr_line += -1
        let curr_foldlevel=b:anyfold_ind_contextual[curr_line]

        if b:anyfold_ind_contextual[curr_line-1] == curr_foldlevel
            let curr_foldlevel += -1
        endif

        while b:anyfold_ind_contextual[curr_line-1] > curr_foldlevel
            if curr_line == 1
                break
            endif
            let curr_line += -1
        endwhile
    endwhile

    call cursor(curr_line,1)
endfunction

function! s:JumpFoldEnd(visual, count1) abort
    if a:visual
        normal! gv
    endif

    let curr_line = line('.')
    let rep=0
    while rep < a:count1
        let rep += 1
        if curr_line == line('$')
            call cursor(line('$'),1)
            return
        endif

        let curr_line += 1
        let curr_foldlevel=b:anyfold_ind_contextual[curr_line-2]

        if b:anyfold_ind_contextual[curr_line-1] == curr_foldlevel
            let curr_foldlevel += -1
        endif

        while b:anyfold_ind_contextual[curr_line-1] > curr_foldlevel
            if curr_line == line('$')
                break
            endif
            let curr_line += 1
        endwhile
    endwhile

    call cursor(curr_line,1)
endfunction

function! s:JumpPrevFoldEnd(visual, count1) abort
    if a:visual
        normal! gv
    endif
    let rep=0
    while rep < a:count1
        let rep += 1
        normal! kzkj0
    endwhile
endfunction

function! s:JumpNextFoldStart(visual, count1) abort
    if a:visual
        normal! gv
    endif
    let rep=0
    while rep < a:count1
        let rep += 1
        normal! zj
    endwhile
endfunction

"----------------------------------------------------------------------------/
" Debugging
"----------------------------------------------------------------------------/
function! s:EchoIndents(mode) abort
    if a:mode == 1
        echom s:IsComment(line('.'))
    elseif a:mode == 2
        echom b:anyfold_ind_actual[line('.')-1]
    elseif a:mode == 3
        echom b:anyfold_ind_contextual[line('.')-1]
    endif
endfunction

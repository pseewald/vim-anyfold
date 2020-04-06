"----------------------------------------------------------------------------/
" Initialization: Activation of requested features
"----------------------------------------------------------------------------/
function! anyfold#init(force) abort

    if exists("g:anyfold_activate")
        let b:anyfold_activate = g:anyfold_activate
    endif

    if !a:force
        if !exists("b:anyfold_activate")
            return
        elseif !b:anyfold_activate
            return
        endif
    endif

    " make sure initialisation only happens once
    if exists("b:anyfold_initialised")
        return
    else
        let b:anyfold_initialised = 1
    endif

    if exists("b:anyfold_activate")
        echoerr "anyfold: 'let anyfold_activate=1' is deprecated, replace by command ':AnyFoldActivate' (see ':h AnyFoldActivate')"
    endif

    if exists("b:AnyFoldActivate") || exists("g:AnyFoldActivate")
        echoerr "anyfold: 'let AnyFoldActivate=1' does not work, ':AnyFoldActivate' is a command! (see ':h AnyFoldActivate')"
    endif

    if s:AnyfoldDisable()
        return
    endif

    " Options and defaults
    if !exists('g:_ANYFOLD_DEFAULTS')
        let g:_ANYFOLD_DEFAULTS = {
                    \ 'identify_comments':            1,
                    \ 'fold_comments':                0,
                    \ 'comments':      ['comment', 'string', 'preproc', 'include'],
                    \ 'fold_toplevel':                0,
                    \ 'fold_display':                 1,
                    \ 'motion':                       1,
                    \ 'debug':                        0,
                    \ 'fold_size_str':           '%s lines',
                    \ 'fold_level_str':             ' + ',
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

    let s:comments_string = ""
    if len(g:anyfold_comments) > 0
        let s:comments_string = join(g:anyfold_comments, "\\|")
    endif

    " calculate indents for first time
    call s:InitIndentList()

    " folds are always updated when buffer has changed
    autocmd TextChanged,InsertLeave <buffer> call s:ReloadFolds()

    " set vim options
    call anyfold#set_options()

    " for some events, options need to be set again:
    " - foldexpr is local to current window so it needs update when
    "   user enters another window (WinEnter).
    " - reset foldmethod that may be overwritten by syntax files (BufNewFile, BufRead)
    "   (see #15, this replaces pr #16)
    autocmd WinEnter,BufNewFile,BufRead <buffer> call anyfold#set_options()

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
        noremap <script> <buffer> <silent> <F7>
                    \ :call <SID>EchoIndents(1)<cr>
        noremap <script> <buffer> <silent> <F8>
                    \ :call <SID>EchoIndents(2)<cr>
        noremap <script> <buffer> <silent> <F9>
                    \ :call <SID>EchoIndents(3)<cr>
        noremap <script> <buffer> <silent> <F10>
                    \ :call <SID>EchoIndents(4)<cr>
    endif

    silent doautocmd User anyfoldLoaded

endfunction

"----------------------------------------------------------------------------/
" Set fold related vim options needed for anyfold
"----------------------------------------------------------------------------/
function! anyfold#set_options() abort

    if s:AnyfoldDisable()
        return
    endif

    setlocal foldmethod=expr
    set foldexpr=b:anyfold_ind_buffer[v:lnum-1]
    if g:anyfold_fold_display
        setlocal foldtext=MinimalFoldText()
    endif

endfunction

"----------------------------------------------------------------------------/
" Identify comment lines
"----------------------------------------------------------------------------/
function! s:MarkCommentLines(line_start, line_end) abort
    let commentlines = []
    let curr_line = a:line_start
    while curr_line <= a:line_end
        let commentlines += [s:CommentLine(curr_line)]
        let curr_line += 1
    endwhile
    return commentlines
endfunction

"----------------------------------------------------------------------------/
" Check if line is comment or preprocessor statement
"----------------------------------------------------------------------------/
function! s:CommentLine(lnum) abort
    if getline(a:lnum) !~? '\v\S'
        " empty line
        return 0
    endif

    if g:anyfold_identify_comments == 0
        return 0
    endif

    if g:anyfold_identify_comments >= 1
        " using foldignore option to detect comments
        " note: this may not work for multiline comments
        for char in split(&foldignore, '\zs')
            if char ==? getline(a:lnum)[indent(a:lnum)]
                return 1
            endif
        endfor
    endif

    if g:anyfold_identify_comments >= 2
        " synID is very slow, therefore we only call this if user wants highest
        " accuracy for comment identification
        if empty(s:comments_string)
            return 0
        endif
        return synIDattr(synID(a:lnum,indent(a:lnum)+1,1),"name") =~? s:comments_string
    endif

    return 0

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
"----------------------------------------------------------------------------/
function! s:ConsiderLine(lnum) abort
    if getline(a:lnum) !~? '\v\S'
        " empty line
        return 0
    elseif getline(a:lnum) =~? '^\W\+$'
        " line containing braces or other non-word characters that will not
        " define an indent
        return 0
    elseif s:IsComment(a:lnum)
        " comment line
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
        let b:anyfold_commentlines = s:MarkCommentLines(1, line('$'))
        lockvar! b:anyfold_commentlines
    endif

    let b:anyfold_ind_actual = s:ActualIndents(1, line('$'))
    let b:anyfold_ind_contextual = s:ContextualIndents(0, 1, line('$'), b:anyfold_ind_actual)
    let b:anyfold_ind_buffer = s:BufferIndents(1, line('$'))

    lockvar! b:anyfold_ind_buffer
    lockvar! b:anyfold_ind_actual
    lockvar! b:anyfold_ind_contextual
endfunction

"----------------------------------------------------------------------------/
" get actual indents
" don't depend on context
" Note: this implements good heuristics also for braces
"----------------------------------------------------------------------------/
function! s:ActualIndents(line_start, line_end) abort
    let curr_line = a:line_start
    let offset = curr_line

    " need to start with a line that has an indent
    while curr_line > 1 && s:ConsiderLine(curr_line) == 0
        let curr_line -= 1
    endwhile
    let offset -= curr_line

    let ind_list = [indent(curr_line)]
    while curr_line < a:line_end
        let curr_line += 1
        let prev_indent = ind_list[-1]
        let next_indent = indent(s:NextNonBlankLine(curr_line))
        if s:ConsiderLine(curr_line)
            " non-empty lines that define an indent
            let ind_list += [indent(curr_line)]
        elseif getline(curr_line) =~? '^\s*{\W*$'
            " line consisting of { brace: this increases indent level
            let ind_list += [min([ind_list[-1] + shiftwidth(), next_indent])]
        elseif getline(curr_line) =~? '^\s*}\W*$'
            " line consisting of } brace: this has indent of line with matching {
            let restore = winsaveview()
            keepjumps exe curr_line
            keepjumps normal! %
            let br_open_pos = getpos('.')[1]
            call winrestview(restore)
            if br_open_pos < curr_line && br_open_pos >= a:line_start - offset
                let ind_list += [ind_list[offset + br_open_pos - a:line_start]]
            else
                " in case matching { does not exist or is out of range
                let ind_list += [max([prev_indent, next_indent])]
            endif
        else
            let ind_list += [max([prev_indent, next_indent])]
        endif
    endwhile
    return ind_list[offset : ]
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
" Note: update mechanism may not always update brace based folds since it
" detects block to be updated based on indents.
"----------------------------------------------------------------------------/
function! s:ReloadFolds() abort

    " many of the precautions taken are necessary because the marks of
    " previously changed text '[ & '] are not always reliable, for instance if
    " text is inserted by a script. There may be vim bugs such as
    " vim/vim#1281.
    "

    " for some reason, need to redraw, otherwise vim will display
    " beginning of file before jumping to last position
    redraw

    let changed_start = min([getpos("'[")[1], line('$')])
    let changed_end = min([getpos("']")[1], line('$')])

    " fix that getpos(...) may evaluate to 0 in some versions of Vim
    let changed_start = max([changed_start, 1])
    let changed_end = max([changed_end, 1])

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
        unlockvar! b:anyfold_commentlines
        let b:anyfold_commentlines = s:ExtendLineList(b:anyfold_commentlines, changed[0], changed[1])
        if changed_lines > 0
            let b:anyfold_commentlines[changed[0]-1 : changed[1]-1] = s:MarkCommentLines(changed[0], changed[1])
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

    set foldexpr=b:anyfold_ind_buffer[v:lnum-1]

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
" disable fold text and return whether anyfold should be disabled
"----------------------------------------------------------------------------/
function! s:AnyfoldDisable() abort
    if &diff || (&buftype ==# "terminal")
        if &foldtext=="MinimalFoldText()"
            setlocal foldtext=foldtext() " reset foldtext to default
        endif
        return 1
    else
        return 0
    endif
endfunction

"----------------------------------------------------------------------------/
" Improved fold display
" Inspired by example code by Greg Sexton
" http://gregsexton.org/2011/03/27/improving-the-text-displayed-in-a-vim-fold.html
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
    let foldSizeStr = " " . substitute(g:anyfold_fold_size_str, "%s", string(foldSize), "g") . " "
    let foldLevelStr = repeat(g:anyfold_fold_level_str, v:foldlevel)
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
            call s:CursorJump(1,1)
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

    call s:CursorJump(curr_line,1)
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
            call s:CursorJump(line('$'),1)
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

    call s:CursorJump(curr_line,1)
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

function! s:CursorJump(lnum, col) abort
    execute "normal " . a:lnum . "G" . a:col . "|"
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
    elseif a:mode == 4
        echom b:anyfold_ind_buffer[line('.')-1]
    endif
endfunction

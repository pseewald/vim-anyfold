if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

setlocal filetype=python

if !exists("g:anyfold_activate")
    finish
elseif !g:anyfold_activate
    finish
endif

let s:indent = 4
let s:comment_char = '#'

call anyfold#init(s:indent, s:comment_char)

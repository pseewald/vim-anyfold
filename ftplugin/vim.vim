if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

setlocal filetype=vim

if !exists("g:anyfold_activate")
    finish
elseif !g:anyfold_activate
    finish
endif

let s:nindent = 4
let s:comment_char = '"'

let s:equalprg = ''
let s:equalprg_args = ''

call anyfold#init(s:nindent, s:comment_char, s:equalprg, s:equalprg_args)

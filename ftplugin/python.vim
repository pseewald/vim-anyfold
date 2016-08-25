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

" we don't use autopep8 by default since python syntax requires correct
" indents anyway (and autopep8 does not even fix bad indents)
let s:equalprg = ''
let s:equalprg_args = ''

call anyfold#init(s:indent, s:comment_char, s:equalprg, s:equalprg_args)

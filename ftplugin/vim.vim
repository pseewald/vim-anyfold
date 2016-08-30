if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

if !exists("g:anyfold_activate")
    finish
elseif !g:anyfold_activate
    finish
endif

let s:comment_sym = '"'

au BufEnter * call anyfold#init(s:comment_sym)
autocmd! fallback BufEnter *

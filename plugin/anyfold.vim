" This is the filetype independent fallback plugin, it will be overridden by ftplugin if it exists
if exists("b:loaded_anyfold_fallback")
    finish
endif
let b:loaded_anyfold_fallback = 1

if !exists("g:anyfold_activate")
    finish
elseif !g:anyfold_activate
    finish
endif

let s:nindent = 4
let s:comment_char = ''

let s:equalprg = ''
let s:equalprg_args = ''

" ftplugin will delete this augroup
augroup fallback
au BufEnter * call anyfold#init(s:nindent, s:comment_char, s:equalprg, s:equalprg_args)
augroup end

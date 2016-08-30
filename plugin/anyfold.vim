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

let s:comment_sym = ''

" ftplugin will delete this augroup if it exists
augroup fallback
au BufEnter * call anyfold#init(s:comment_sym)
augroup end

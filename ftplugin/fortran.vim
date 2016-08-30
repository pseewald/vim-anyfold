if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

if !exists("g:anyfold_activate")
    finish
elseif !g:anyfold_activate
    finish
endif

let s:comment_sym = '!'

let b:anyfold_equalprg = 'fprettify'

" fixme: passing shiftwidth in this way is a bit hackish and not very user-friendly
au Bufenter * exe 'let b:anyfold_equalprg_args = "--no-report-errors --indent=".&shiftwidth'

let b:anyfold_docubox_mark = '!>'

au BufEnter * call anyfold#init(s:comment_sym)
autocmd! fallback BufEnter *

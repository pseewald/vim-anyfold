if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

setlocal filetype=fortran

if !exists("g:anyfold_activate")
    finish
elseif !g:anyfold_activate
    finish
endif

let s:indent = 3
let s:comment_char = '!'

let s:equalprg = 'fprettify'
let s:equalprg_args = '--no-report-errors'

let b:anyfold_docubox_mark = '!>'
let b:anyfold_docubox_start = ''
let b:anyfold_docubox_end = ''

call anyfold#init(s:indent, s:comment_char, s:equalprg, s:equalprg_args)

if exists('g:anyfold_lang_settings')
    if g:anyfold_lang_settings
        let g:fortran_do_enddo=1


    endif
endif

if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

if !exists("g:anyfold_activate")
    finish
elseif !g:anyfold_activate
    finish
endif

let s:nindent = 3
let s:comment_char = '!'

let s:equalprg = 'fprettify'
let s:equalprg_args = '--no-report-errors --indent=<nindent>'

let b:anyfold_docubox_mark = '!>'
let b:anyfold_docubox_start = ''
let b:anyfold_docubox_end = ''

if exists('g:anyfold_ftsettings')
    if g:anyfold_ftsettings
        let g:fortran_do_enddo=1


    endif
endif

au BufEnter call anyfold#init(s:nindent, s:comment_char, s:equalprg, s:equalprg_args)
autocmd! fallback BufEnter *

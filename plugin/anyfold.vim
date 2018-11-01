if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

command! AnyFoldActivate call anyfold#init(1)

" deprecated initialization using anyfold_activate variable
" still works but echoes a warning
au BufNewFile,BufRead * call anyfold#init(0)

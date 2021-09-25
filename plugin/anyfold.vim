if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

command! -bang AnyFoldActivate call anyfold#init(1, '<bang>' == '!')

" deprecated initialization using anyfold_activate variable
" still works but echoes a warning
au BufNewFile,BufRead * call anyfold#init(0, "n/a")


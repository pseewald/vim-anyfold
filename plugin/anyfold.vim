au BufNewFile,BufRead * call anyfold#reset()
if exists("b:loaded_anyfold")
    finish
endif
let b:loaded_anyfold = 1

au BufEnter * call anyfold#init()

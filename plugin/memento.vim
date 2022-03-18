augroup AutoMementoGroup
    autocmd!
    autocmd BufUnload * lua require("memento").store_position()
    autocmd VimEnter * lua require("memento").load()
augroup END

command! MementoToggle lua require("memento").toggle()
command! MementoClearHistory lua require("memento").clear_history()


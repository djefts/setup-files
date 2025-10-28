"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Info
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Much of the content of this file was copied/modified from https://github.com/amix/vimrc

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Disable compatibility with vi
set nocompatible
" Ignore non-text files that break Vim
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
" :W sudo saves the file (useful for handling the permission-denied error)
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vertical movement with j/k moves 7 lines at a time
set so=7
" Display current mode on last line
set showmode
" Enable type file detection
filetype on
" Show line numbers
set number
" Highlight current row of cursor
set cursorline
" Highlight current column of cursor
" set cursorcolumn
" Enable syntax highlighting
syntax enable
" Don't redraw while executing macros (good performance config)
set lazyredraw
" Show matching brackets when text indicator is over them
set showmatch
set mat=2
" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500
" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l
" Disable scrollbars (real hackers don't use scrollbars for navigation!)
set guioptions-=r
set guioptions-=R
set guioptions-=l
set guioptions-=L

""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2
set stl= " Clear status line
" LEFT
set stl+=\ %{HasPaste()}%1*%M%* " Show if paste mode is enabled and if file has been modified
set stl+=\ %.50F " limit filename path to 50 chars
set stl+=%=
" RIGHT
set stl+=\ [%R%W%Y] " IsReadOnly, IsPreviewWindow, FileType
set stl+=\ CWD:\ %{getcwd()}%h
set stl+=\ Row:\ %l/%L\ \ Col:\ %c " Row: [Line]/[Total Lines]  Col: [Column]

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" spaces rule, tabs drool
set expandtab
" 4-space indents, tab key indents
set smarttab shiftwidth=4
" different width for TABs and indents just in case
set tabstop=8 softtabstop=0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Turn persistent undo on
"    means that you can undo even when you close a buffer/VIM
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" try
"     set undodir=~/.vim_runtime/temp_dirs/undodir
"     set undofile
" catch
" endtry

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE, '
    endif
    return ''
endfunction

" Don't close window, when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
    let l:currentBufNum = bufnr("%")
    let l:alternateBufNum = bufnr("#")

    if buflisted(l:alternateBufNum)
        buffer #
    else
        bnext
    endif

    if bufnr("%") == l:currentBufNum
        new
    endif

    if buflisted(l:currentBufNum)
        execute("bdelete! ".l:currentBufNum)
    endif
endfunction

function! CmdLine(str)
    call feedkeys(":" . a:str)
endfunction

function! VisualSelection(direction, extra_filter) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", "\\/.*'$^~[]")
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'gv'
        call CmdLine("Ack '" . l:pattern . "' " )
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction

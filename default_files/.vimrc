"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Info
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Much of the content of this file was copied/modified from https://github.com/amix/vimrc

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif
" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)')) | PlugInstall --sync | source $MYVIMRC | endif
" vim-plug
call plug#begin()
Plug 'tpope/vim-sensible'
Plug 'aymericbeaumet/vim-symlink'
call plug#end()

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
" Mouse scrolling
set mouse=a
" Vertical movement with j/k moves 7 lines at a time
set so=7
" Display current mode on last line
set showmode
" Enable type file detection
filetype on
" Enable filetype plugins and indent files
filetype plugin indent on
" Show line numbers
set number
" Highlight current row of cursor
" set cursorline
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
" Sync yank with computer clipboard
set clipboard=unnamedplus

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
" Auto-indent new lines
set autoindent
" Smart indent for code blocks
set smartindent
" 4-space indents, tab key indents (default, will be auto-detected per file)
set smarttab shiftwidth=4
" different width for TABs and indents just in case
set tabstop=8 softtabstop=0
" Auto-detect indentation (2 or 4 spaces) when opening files
autocmd BufReadPost * call DetectIndent()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Turn persistent undo on
"    means that you can undo even when you close a buffer/VIM
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
try
    set undodir=~/.vim_runtime/temp_dirs/undodir
    set undofile
catch
endtry

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

" Detect indentation (2 or 4 spaces) from file content
function! DetectIndent()
    let l:two_space = 0
    let l:four_space = 0
    let l:max_lines = min([line('$'), 100])

    " Sample first 100 lines
    for l:lnum in range(1, l:max_lines)
        let l:line = getline(l:lnum)
        " Check for lines starting with 2 spaces (but not 4)
        if l:line =~ '^\s\s\S' && l:line !~ '^\s\s\s\s'
            let l:two_space += 1
        endif
        " Check for lines starting with 4 spaces
        if l:line =~ '^\s\s\s\s\S'
            let l:four_space += 1
        endif
    endfor

    " Set indentation based on what we found
    if l:two_space > l:four_space && l:two_space > 5
        setlocal shiftwidth=2 softtabstop=2
    elseif l:four_space > 5
        setlocal shiftwidth=4 softtabstop=4
    endif
endfunction


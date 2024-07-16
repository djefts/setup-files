" Only do this part when compiled with support for autocommands.
if has("autocmd")
    " Use filetype detection and file-based automatic indenting.
    filetype plugin indent on

    " Use actual tab chars in Makefiles.
    autocmd FileType make set tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab
endif

" For everything else:
set shiftwidth=4 smarttab " 4-space indents, tab key indents
set expandtab " expand TABs to spaces
set tabstop=8 softtabstop=0 " different width for TABs and indents just in case

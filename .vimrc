" Settings
let mapleader=","                                                    " set the command prefix from the default '\' to ','
set lazyredraw                                                       " don't redraw in between macros
set backspace=indent,eol,start                                       " allow backspace to erase previously entered characters
set wildmenu                                                         " visual autocomplete for command menu


" Files
set hidden                                                           " switch buffers without saving first
set autoread                                                         " reload files changed outside Vim if the buffer is unmodified
set splitbelow splitright                                            " open new splits below and to the right
set undofile                                                         " keep undo history across sessions
for s:dir in ['swp', 'undo', 'bak']
  call mkdir(expand('~/.vim/.local/' . s:dir), 'p', 0700)
endfor
set directory=~/.vim/.local/swp//                                    " store swap files centrally, named after the full path
set undodir=~/.vim/.local/undo//                                     " store undo files centrally, named after the full path
set backupdir=~/.vim/.local/bak//                                    " store backup files centrally, named after the full path
" never persist undo history for files in temporary directories
augroup NoUndoFileInTmp
  autocmd!
  autocmd BufWritePre /tmp/*,/private/tmp/*,/var/tmp/*,/var/folders/*,/private/var/folders/*,/dev/shm/* setlocal noundofile
augroup END


" Folding
set foldenable                                                       " enable folding
set foldlevelstart=10                                                " open most folds by default
set foldnestmax=10                                                   " 10 nested fold max
set foldmethod=indent                                                " fold based on indent level
" space opens/closes folds
nnoremap <space> za


" Indentation
filetype plugin indent on                                            " enable the default indent plugin
set expandtab                                                        " tabs are spaces
set shiftwidth=2                                                     " number of spaces to move when using << or >>
set softtabstop=2                                                    " number of spaces in tab when editing
set tabstop=2                                                        " number of visual spaces per tab
set autoindent                                                       " new line has the same indentation as the present line


" Search
" <comma>,<space> will turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>
syntax on                                                            " enable syntax processing
set hlsearch                                                         " highlight matches
set incsearch                                                        " search as characters are entered
set ignorecase                                                       " search is not case sensitive
set showmatch                                                        " highlight matching parantheses
set smartcase                                                        " search is case sensitive if it has both upper and lower case


" Navigation
" move vertically down by visual line using j/k
nnoremap j gj
nnoremap k gk
set number                                                           " show line numbers on the left pane
set ruler                                                            " show line and column number in the status bar
set scrolloff=10                                                     " number of lines to be shown above and below the cursor
set showcmd                                                          " show information about the current command going on


" Shortcuts
" <comma>,sv will source ~/.vimrc
nnoremap <leader>sv :source $MYVIMRC<CR>
" <escape>,s will save the file
map <Esc>s :w<CR>
" <escape>,S will save the file with elevated privileges
map <Esc>S :w !sudo tee % > /dev/null<CR>
" <escape>,w will save the file and then quit
map <Esc>w :wq!<CR>
" <escape>,q will quit the file without saving
map <Esc>q :q!<CR>
" F3 will remove all trailing whitespaces
nnoremap <silent> <F3> :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s<CR>
" F4 will toggle spell check
map <F4> :setlocal spell!<CR>
" F5 will toggle absolute line numbers
map <F5> :set nu! <Bar> :GitGutterSignsToggle<CR>
" F6 will toggle relative line numbers
map <F6> :set rnu!<CR>
" F9 will toggle all control characters
map <F9> :set list!<CR>


" Plugins
" execute the below command for setting up vim-plug, a minimalistic Vim plugin manager
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" then execute :PlugInstall inside Vim to set up all these plugins
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree', {'on': 'NERDTreeToggle'}                  " tree explorer
Plug 'dense-analysis/ale'                                            " asynchronous lint engine
Plug 'tpope/vim-surround'                                            " quoting/parenthesizing made simple
Plug 'airblade/vim-gitgutter'                                        " show git diff in the sign column
Plug 'chr4/nginx.vim'                                                " recognize Nginx config files
call plug#end()


" Built-in packages
packadd! comment                                                     " gcc / gc{motion} toggles comments
packadd! editorconfig                                                " apply a project's .editorconfig settings
packadd! matchit                                                     " % also jumps between if/else/endif, HTML tags
if !has('mac')
  let g:osc52_disable_paste = 1                                      " copy only; an OSC 52 paste can hang
  let g:osc52_force_avail = 1                                        " tmux hides OSC 52 support from detection
  packadd osc52
  set clipmethod+=osc52                                              " "+y copies to the local clipboard over SSH
endif
runtime ftplugin/man.vim
set keywordprg=:Man                                                  " K opens the man page in a Vim split


" Appearance
colorscheme slate                                                    " set color scheme
" change the selected menu entry's background color to make it more visible
highlight PmenuSel ctermbg=4
" highlight trailing whitespaces
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
augroup ExtraWhitespace
  autocmd!
  autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
  autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/
  autocmd BufWinLeave * call clearmatches()
augroup END

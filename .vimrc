" Settings
let mapleader=","                                                    " set the command prefix from the default '\' to ','
set ttimeout ttimeoutlen=100                                         " wait at most 100ms after Esc for the rest of a key code
set display=truncate                                                 " show @@@ on the last line when it doesn't fit instead of hiding it
set nrformats-=octal                                                 " Ctrl-A on 007 gives 008, not 010
set updatetime=100                                                   " show git signs 100ms after a change instead of 4s
set wildoptions=pum,fuzzy                                            " complete : commands in a popup menu with fuzzy matching
set formatoptions+=j                                                 " drop the comment leader when joining commented lines
set listchars=eol:$,tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+      " what F9's list mode shows for each invisible character


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
" reopen a file at the last cursor position, except for commit messages, rebase todos and diffs
function! s:RestoreCursor() abort
  if line("'\"") >= 1 && line("'\"") <= line("$") && &filetype !~# 'commit' && index(['xxd', 'gitrebase', 'tutor'], &filetype) == -1 && !&diff
    execute "normal! g`\""
  endif
endfunction
augroup RestoreCursor
  autocmd!
  autocmd BufReadPost * call s:RestoreCursor()
augroup END
" :DiffOrig shows the unsaved changes as a diff against the file on disk
command! DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis | wincmd p | diffthis


" Folding
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
set hlsearch                                                         " highlight matches
set incsearch                                                        " search as characters are entered
set ignorecase                                                       " search is not case sensitive
set showmatch                                                        " highlight matching parentheses
set smartcase                                                        " search is case sensitive if it has both upper and lower case


" Navigation
" move by visual line using j/k, but by real line when given a count
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'
set number                                                           " show line numbers on the left pane
set signcolumn=yes                                                   " always reserve the sign column so text doesn't shift
set scrolloff=10                                                     " number of lines to be shown above and below the cursor


" Shortcuts
" <comma>,sv will source ~/.vimrc
nnoremap <leader>sv :source $MYVIMRC<CR>
" <comma>,n will toggle the file tree
nnoremap <leader>n :NERDTreeToggle<CR>
" <comma>,w will save the file
nnoremap <leader>w :w<CR>
" <comma>,W will save the file with elevated privileges
nnoremap <leader>W :w !sudo tee % > /dev/null<CR>
" <comma>,x will save the file and then quit
nnoremap <leader>x :x<CR>
" <comma>,q will quit the file without saving
nnoremap <leader>q :q!<CR>
" Ctrl-U in insert mode can be undone instead of eating the whole line
inoremap <C-U> <C-G>u<C-U>
" Ctrl-W in insert mode can be undone instead of eating the whole word
inoremap <C-W> <C-G>u<C-W>
" F3 will remove all trailing whitespace
nnoremap <silent> <F3> :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s<CR>
" F4 will toggle spell check
map <F4> :setlocal spell!<CR>
" F5 will toggle absolute line numbers and the sign column
nnoremap <F5> :set nu! <Bar> let &signcolumn = &signcolumn ==# 'yes' ? 'no' : 'yes'<CR>
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
call plug#end()


" Built-in packages
packadd! comment                                                     " gcc / gc{motion} toggles comments
packadd! editorconfig                                                " apply a project's .editorconfig settings
packadd! matchit                                                     " % also jumps between if/else/endif, HTML tags
packadd! hlyank                                                      " briefly highlight the yanked region
if !has('mac')
  let g:osc52_disable_paste = 1                                      " copy only; an OSC 52 paste can hang
  let g:osc52_force_avail = 1                                        " tmux hides OSC 52 support from detection
  packadd osc52
  set clipmethod+=osc52                                              " "+y copies to the local clipboard over SSH
endif
runtime ftplugin/man.vim
set keywordprg=:Man                                                  " K opens the man page in a Vim split


" Appearance
syntax on                                                            " enable syntax processing
if &t_Co >= 256
  set termguicolors                                                  " 24-bit colors; iTerm2 and tmux both support them
endif
colorscheme slate                                                    " set color scheme
" change the selected menu entry's background color to make it more visible
highlight PmenuSel ctermbg=4 guibg=DarkBlue
" highlight trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
augroup ExtraWhitespace
  autocmd!
  autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
  autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/
  autocmd BufWinLeave * call clearmatches()
augroup END

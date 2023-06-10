# shellcheck shell=bash


# Load custom key bindings for the shell.
export INPUTRC="$HOME/.inputrc"
# Set default text editor.
export EDITOR="vim"
# Enable color support for Less. Also, search within is case insensitive unless
# the pattern contains uppercase letters.
export LESS="-Ri"


# Configure command history.
HISTCONTROL=ignoreboth                              # don't store commands if they start with a space, or if they are duplicates
HISTFILE="$HOME/.bash_history"                      # store the history of commands that were executed over here
HISTSIZE='INFINITE'                                 # number of lines that are allowed in the history file at the start/end of a session
HISTTIMEFORMAT="%d/%m/%y %T "                       # timestamp format to associate each command with
PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND%;};}"
PROMPT_COMMAND+="history -a"                        # history buffer to be flushed after every command


# Shell options.
shopt -s autocd                                     # auto-cd when entering just a path
shopt -s cdspell                                    # this will correct minor spelling errors in a cd command
shopt -s checkjobs                                  # defer the exit if any of the background jobs are running
shopt -s checkhash                                  # immediately pick up renamed executables
shopt -s checkwinsize                               # fix line wrap on window resize
shopt -s cmdhist                                    # force multi-line commands to be stored in the history as a single line
shopt -s direxpand                                  # replace directory names with the results of word expansion
shopt -s dirspell                                   # auto-complete directory names even if there's a minor spelling mistake
shopt -s dotglob                                    # consider filenames beginning with a '.' for filename expansions
shopt -s expand_aliases                             # expand aliases in scripts
shopt -s extglob                                    # enhance pattern matching features
shopt -s globstar                                   # expand "**" to match files in subdirectories as well
shopt -s histappend                                 # append to history rather than overwrite (avoid history loss)
shopt -s histreedit                                 # make fixing failed history substitution easier
shopt -s hostcomplete                               # tab-completion of hostnames after @
shopt -s huponexit                                  # send SIGHUP to all background jobs before exiting
shopt -s nocaseglob                                 # let file name expansions be case insensitive
shopt -s nullglob                                   # file name pattern expand to NULL if there's no match


# Load Fzf (https://github.com/junegunn/fzf), a general-purpose command-line
# fuzzy finder.
#
# Dependencies:
#       dnf install fd-find fzf
if [[ "$OSTYPE" == "linux"* ]] ; then
    include "/usr/share/fzf/shell/key-bindings.bash"
elif [[ "$OSTYPE" == "darwin"* ]] ; then
    include "$HOMEBREW_PREFIX/opt/fzf/shell/completion.bash"
    include "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.bash"
fi
_fzf_compgen_dir() { fd --type d --hidden --follow --exclude ".git" --exclude ".hg" . "$1" ; }
_fzf_compgen_path() { fd --hidden --follow --exclude ".git" --exclude ".hg" . "$1" ; }
export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --exclude .git"
export FZF_DEFAULT_OPTS="--bind 'ctrl-a:select-all'"


# Configure Git (https://github.com/git/git) prompt.
#
# Dependencies:
#       dnf install git
if [[ "$OSTYPE" == "linux"* ]] ; then
    include "/usr/share/git-core/contrib/completion/git-prompt.sh"
fi


# Configure Ripgrep (https://github.com/BurntSushi/ripgrep), a faster
# alternative to Grep.
#
# Dependencies:
#       dnf install ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

#!/usr/env zsh

# prints divider
# _p_divider [bg] [fg]
_p_divider(){
    _p_fk ${1:-$C_BG} ${2:-$C_FG} $DIVIDER
}

# XXX broken
_p_success(){
    if [ $? -ne 0 ]; then
        _p_fk $1 $2 " ! "
    fi
}

# prints $nick if set
_p_nick(){
    if [ -n "$nick" ]; then
        _p_fk $1 $2 " $nick "
    fi
}

# prints first character of current username
_short_user(){
    printf "$USER" | cut -c1
}

# displays first character of username and host
# optionally colors the @host with given color
# _p_main [host color]
# Ex: c@theta
_p_main(){
    _p_fk $C_BG $C_FG "$(_short_user)@"
    _p_fk $1 $C_FG "%M"
}

_p_location(){
    _p_k $C_FG "%F{$C_BG}%~%f"
}

_timestamp(){
    date +%s
}

# Caches status of current directory after first call
# Use this if you need to know if the cwd is a git repo
# Ex: _is_git && echo "In a git repo" || echo "No repo here"
_is_git(){
    if [[ -z "$_IS_GIT" ]]; then
        # Run a check for a git repo, if it takes over
        # a second, mark this directory as slow
        start=$(_timestamp)
        git rev-parse --is-inside-work-tree > /dev/null 2>&1
        _IS_GIT="$?"
        stop=$(_timestamp)
        if [ $((stop - start)) -gt 1 ];then
            _IS_SLOW=1
        fi
    fi

    return $_IS_GIT
}

# Use this if you need to know if the cwd is slow (NFS, etc)
# Uses _IS_SLOW to hold value, is set by _is_git
# Ex: _is_slow && do_something_conservative || do_something_expensive
_is_slow(){
    test "$_IS_SLOW" -eq 1
}

# prints git branch name
# Ex: (master)
_p_git(){
    if _is_git && ! _is_slow; then
        _p_fk $1 $2 "("
        git rev-parse --abbrev-ref HEAD | tr -d '\n'
        _p_fk $1 $2 ") "
    fi
}

# prints color name for git usage
# if not in git $reset_color
# if in clean git repo green
# if in dirty git repo yellow
_p_git_color(){
    if ! _is_git; then
        echo -n "$reset_color"
        return
    else
        if [ -z "$(git diff --name-only)" ]; then
            echo -n "$C_GREEN"
        else
            echo -n "$C_YELLOW"
        fi
    fi
}

# files_changed insertions deletions
_p_git_diffs(){
    if _is_git;then
        i=$(git diff --shortstat)
        changes=$(echo "$i" | awk '{print $1}')
        additions=$(echo "$i" | awk '{print $4}')
        deletions=$(echo "$i" | awk '{print $6}')

        if [ "$changes" -gt "0" ]; then
            _p_f $1 "~$changes "
            _p_f $2 "+$additions "
            _p_f $3 "-$deletions"
        fi
    fi
}

# prints text with given back and foreground
_p_fk(){
    f=$1
    k=$2
    shift
    shift
    _p_f $f $(_p_k $k $*)
}

# prints text with given background
_p_k(){
    echo -n "%K{$1}"
    shift
    echo -n "$*%k"
}

# prints text with given foreground
_p_f(){
    echo -n "%F{$1}"
    shift
    echo -n "$*%f"
}

# prints a space with correct foreground color
_p_space(){
    _p_k $C_FG " "
}

# loads color variables
_p_color_init(){
    C_BLACK="black"
    C_BLUE="blue"
    C_GREEN="green"
    C_MAGENTA="magenta"
    C_RED="red"
    C_YELLOW="yellow"

    C_BG=$C_MAGENTA
    C_FG=$C_BLACK
}

# Left side of prompt
_p(){
    _p_color_init

    # Setup the constants we'll need
    DIVIDER=""
    DIVIDER2=""
    BRANCH=""

    # Generate the prompt
    _p_space
    _p_main $C_GREEN
    _p_space
    _p_location
    _p_space
    _p_divider
    _p_space
}

# Right side of prompt
_p_right(){
    _p_color_init
    _p_git "$(_p_git_color)" "black" "$(_p_git_color)"
    _p_git_diffs $C_YELLOW $C_GREEN $C_RED
}

setopt PROMPT_SUBST
PROMPT='$(_p)'
RPROMPT='$(_p_right)'

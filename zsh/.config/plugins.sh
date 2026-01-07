#!/usr/bin/env bash


alias lh='eza --hyperlink'
alias lt='eza --tree --level=1 -b --hyperlink --all'
alias ld='eza --only-dirs --sort=modified -b --hyperlink --all'
alias lf='eza --only-files --sort=modified -b --hyperlink --all'


ls() {
    # Special case: ls -ltrh
    if [[ "$*" == "-ltrh" ]]; then
        eza -l --sort=modified  -b --hyperlink --all
        return
    fi

    # Default: forward all other ls calls to eza
    command eza "$@"
}

rgv() {
  rg "$(pbpaste)" --no-ignore-vcs "$@"
}

rgvj() {
  rg "$(pbpaste)" --no-ignore-vcs --no-filename "$@" | paste -sd ',' -
}

rgv_node() {
  rg  --no-ignore "$(pbpaste)" "$@"
}

fds() {
  local pattern="$1"
  shift
  fd --no-ignore-vcs "$pattern" "$@"
} 

# Paste the last item from the clipboard
v(){
  pbpaste | cat "$@"
}

# run pasted command in clipboard
rv(){
  echo "$(pbpaste)"
  eval "$(pbpaste)"
}


source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
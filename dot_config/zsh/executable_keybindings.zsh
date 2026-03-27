# Fork from https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh
#
# -------------------------------------------------------------------------
#                       shortcuts
# -------------------------------------------------------------------------
# ALT-p - Paste the selected file/dir into the command line
#  Paste the selected file/dir into the command line - full path as key-bindings in broot
# ALT-j - cd into the selected directory from fasd
# ALT-e - Open or edit the file from fasd
# ALT-h - Paste the selected command from history into the command line
# ALT-q - Kill process
# ALT-w - Run application
# ALT-v - Edit line in vim with ctrl-e: oh-my-zsh do it by esc; v
# ALT-a - aliases
# ALT-m - fzm fzf-marks

# bindkey '\ef' → alt '^F' ctr
# aliases doesn't work

# global
# export FZF_DEFAULT_OPTS='--height 80% --layout=reverse --border --bind tab:down,shift-tab:up,alt-j:down,alt-k:up,alt-l:accept,ctrl-a:select-all+accept' problem with selection in multi 
export FZF_DEFAULT_OPTS='--height 80% --multi --layout=reverse --cycle --info=inline-right --border --bind alt-j:down,alt-k:up,alt-l:accept,ctrl-a:select-all+accept'

# if not supported iterm protocol change to sixel timg -p s 
export FZF_VIEW_ALL_OPTS='--preview "if [ -d {} ]; then tree -C -L 1 {}; elif [[ {} =~ \.(jpg|jpeg|png|gif|bmp|webp|avif|svg|tiff|ico)$ ]]; then timg -p i -g 60x30 {} 2>/dev/null || echo \"Image: {}\"; else bat --style=numbers --color=always --line-range :500 {}; fi"'
export FZF_FILE_OPTS='--preview "if [[ {} =~ \.(jpg|jpeg|png|gif|bmp|webp|avif|svg|tiff|ico)$ ]]; then timg -p i -g 60x30 {} 2>/dev/null || echo \"Image: {}\"; else bat --style=numbers --color=always --line-range :500 {}; fi"'
OPTS=''

# The code at the top and the bottom of this file is the same as in completion.zsh.
# Refer to that file for explanation.
if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
  __fzf_key_bindings_options="options=(${(j: :)${(kv)options[@]}})"
else
  () {
    __fzf_key_bindings_options="setopt"
    'local' '__fzf_opt'
    for __fzf_opt in "${(@)${(@f)$(set -o)}%% *}"; do
      if [[ -o "$__fzf_opt" ]]; then
        __fzf_key_bindings_options+=" -o $__fzf_opt"
      else
        __fzf_key_bindings_options+=" +o $__fzf_opt"
      fi
    done
  }
fi

'emulate' 'zsh' '-o' 'no_aliases'
{

[[ -o interactive ]] || return 0

# ALT-H - Paste the selected command from history into the command line
fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected=( $(fc -rl 1 | perl -ne 'print if !$seen{(/^\s*[0-9]+\**\s+(.*)/, $1)}++' |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" fzf) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
  return $ret
}
zle     -N   fzf-history-widget
bindkey '\eh' fzf-history-widget
# alias h='fzf-history-widget'

# ALT-Q - Kill process
fzf_killps() { 
	zle -I; 
	ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -${1:-9}; 
} 
zle -N fzf_killps;
bindkey '\eq' fzf_killps

#ALT-w apps list 
fzf-dmenu() { 
    # note: xdg-open has a bug with .desktop files, so we cant use that shit
    selected="$(ls /usr/share/applications | fzf -e)"
    nohup `grep '^Exec' "/usr/share/applications/$selected" | tail -1 | sed 's/^Exec=//' | sed 's/%.//'` >/dev/null 2>&1&
}
zle -N fzf-dmenu;
bindkey '\ew' fzf-dmenu

# Edit line in vim with ctrl-v 
autoload edit-command-line; zle -N edit-command-line
bindkey '\ev' edit-command-line

fzf_fasd_open() {
	zle -I;
 FZF_CMD="fzf $FZF_DEFAULT_OPTS $FZF_FILE_OPTS --query="$1" --no-sort --exit-0 --expect=alt-o,ctrl-e --prompt='fasder: alt-o→open;else→edit >'"
  IFS=$'\n' out=("$(eval "fasder -Rfl | $FZF_CMD" )")
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [ -n "$file" ]; then
	echo "$file" | xargs -r fasder --add
	echo "Selection: $file"
    [ "$key" = alt-o ] && devour xdg-open "$file" || ${EDITOR:-vim} "$file"
	else
		echo "No selection made"
		return 1
	fi
}
zle     -N   fzf_fasd_open
bindkey '\eo' fzf_fasd_open
alias o='fzf_fasd_open'

fzf_fasd_cd() {
	zle -I;
  IFS=$'\n' dir=("$(fasd -Rdl | fzf --query="$1" --exit-0 --no-sort +m)")
  if [[ -z "$dir" ]]; then
	echo "No selection made"
    zle redisplay
    return 0
  fi
	echo "$dir" | xargs -r fasder --add
  zle push-line # Clear buffer. Auto-restored on next prompt.
  BUFFER="cd -- ${(q)dir}"
  zle accept-line
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  zle reset-prompt
  return $ret
}
zle     -N   fzf_fasd_cd;
bindkey '\ej' fzf_fasd_cd
# fzf_fasd_cd doesn't work for alias 
j () {
	local selection
	# +m no multi
	selection=$(fasder -Rdl "$@" | fzf -1 -0 --no-sort +m --height=10)
	if [[ -n "$selection" ]]; then
		echo "Selection: $selection"
		echo "$selection" | xargs -r fasder --add
		cd "$selection" || return 1
	else
		echo "No selection made"
		return 1
	fi
}

FZF_ALIAS_OPTS=${FZF_ALIAS_OPTS:-"--preview-window up:3:hidden:wrap"}

function fzf_alias() {
    local selection
    # use sed with column to work around MacOS/BSD column not having a -l option
    if selection=$(alias |
                       sed 's/=/\t/' |
                       column -s '	' -t |
                       FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALIAS_OPTS" fzf --preview "echo {2..}" --query="$BUFFER" |
                       awk '{ print $1 }'); then
        BUFFER=$selection
    fi
    zle redisplay
}

zle -N fzf_alias
bindkey -M emacs '\ea' fzf_alias
bindkey -M vicmd '\ea' fzf_alias
bindkey -M viins '\ea' fzf_alias

fzf_mark() {
	zle -I;
  local ret=fzm
  zle reset-prompt
  return $ret
}
zle     -N   fzf_mark
bindkey '\em' fzm
alias m='fzm'

} always {
  eval $__fzf_key_bindings_options
  'unset' '__fzf_key_bindings_options'
}

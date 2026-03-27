if (( $+commands[broot] )) {  # Without broot, skip this file

# ------
# Basics
# ------
# source from 
# https://github.com/AndydeCleyre/dotfiles-zsh/tree/main

zmodload zsh/mapfile

# -- Refresh prompt, rerunning any hooks --
# Credit: Roman Perepelitsa
# Original: https://github.com/romkatv/zsh4humans/blob/v2/fn/-z4h-redraw-prompt
.zle_redraw-prompt () {
  for 1 ( chpwd $chpwd_functions precmd $precmd_functions ) {
    if (( $+functions[$1] ))  $1 &>/dev/null
  }
  zle .reset-prompt
  zle -R
}
zle -N .zle_redraw-prompt

# -- Run broot, cd into pathfile if successful --
# Depends: zsh/mapfile
br () {  # [<broot-opt>...]
  emulate -L zsh -o localtraps

  local pathfile=$(mktemp)
  trap "=rm ${(q-)pathfile}" EXIT INT QUIT

  local name=$RANDOM

  if { broot --verb-output "$pathfile" --listen $name $@ } {
    if [[ -r $pathfile ]] {
      local folder=${mapfile[$pathfile]}
      if [[ $folder ]]  cd $folder
    }
  } else {
    return
  }
}

# -- Clear line, run broot, restore line --
# Key: alt+f
# Depends: br
.zle_broot () {
  zle .push-input
  BUFFER="br"
  zle .accept-line
}
zle -N       .zle_broot
bindkey '\ef' .zle_broot  # alt+f

# ----------------
# Fancy Selections
# ----------------
CMD=''

# -- Select files with broot and print each on a line --
# Depends: ~/.config/broot/select.hjson ( https://github.com/AndydeCleyre/dotfiles-broot )
broot-print-files () {  # [broot-arg...]
  emulate -L zsh
  broot \
    --conf "${XDG_CONFIG_HOME:-${HOME}/.config}/broot/select.hjson;${XDG_CONFIG_HOME:-${HOME}/.config}/broot/conf.toml" \
	--cmd="${CMD}" \
    --color yes \
    --git-ignored \
    --show-git-info \
    --no-sizes \
    $@
}

# -- Select a single folder with broot and print it --
# Depends: ~/.config/broot/select-folder.hjson ( https://github.com/AndydeCleyre/dotfiles-broot )
broot-print-folder () {  # [broot-arg...]
  emulate -L zsh
  broot \
    --conf "${XDG_CONFIG_HOME:-${HOME}/.config}/broot/select-folder.hjson;${XDG_CONFIG_HOME:-${HOME}/.config}/broot/conf.toml" \
	--cmd="${CMD}" \
    --color yes \
    --git-ignored \
    --show-git-info \
    --only-folders \
    $@
}

# -- Folder Navigation: Down --
# Key: alt+d
# Depends: broot-print-folder
# Optional: .zle_redraw-prompt (clear_and_foldernav.zsh)
.zle_cd-broot () {
  echoti rmkx
  cd "$(<$TTY broot-print-folder)"
  if (( $+functions[.zle_redraw-prompt] ))  zle .zle_redraw-prompt
  if (( $+functions[_zsh_highlight]     ))  _zsh_highlight
}
zle -N            .zle_cd-broot
bindkey '\ed' .zle_cd-broot  # alt-d

# disable tree view
.zle_cd-shallow() {
	CMD=':toggle_tree'
	.zle_cd-broot
	CMD=''
}
zle -N       .zle_cd-shallow
bindkey '\eD' .zle_cd-shallow  # alt-shift-D

# -- Start writing a for loop over broot-selected paths (each is $f) --
# Key: alt-l
# Depends: broot-print-files
.zle_for-broot () {
  zle .push-input
  LBUFFER='for f ( ${(f)"$(broot-print-files)"} ) {'$'\n''  '
  RBUFFER=' $f'$'\n''}'
}
zle -N       .zle_for-broot
# bindkey '\el' .zle_for-broot
# TODO find shortcut

# -- Complete current word as path using broot --
# Key: alt-p
# Depends: broot-print-files
.zle_insert-path-broot () {
  setopt localoptions extendedglob

  # If the current word is partially typed, grab it (partial),
  # pop it off the line, and create a search string for it (broot_search)
  local partial broot_search
  if [[ ${LBUFFER[-1]/ } ]] {

    # Store it (partial)
    partial=(${(z)LBUFFER})
    partial=${partial[-1]}

    # Remove it from the line
    LBUFFER=${LBUFFER[1,-$#partial-1]}

    # Expand home folder
    partial=${partial/#(\$HOME\/|\~\/)/~\/}

    # Store a sanitized version for broot search (broot_search)
    broot_search=${partial/#~\/}                          # strip leading '~/'
    broot_search=${broot_search//( |:|..\/|\;|\\|\'|\")}  # strip ' ', ':', '../', ';', '\', "'", '"'
    broot_search=${broot_search//.\/}                     # strip './'
    broot_search=${broot_search//\//\\/}                  # replace '/' with '\/'

  }

  # If resulting search string starts with '.' or ends with '/.',
  # search hidden files (can be slow)
  local show_hidden=--no-hidden
  if [[ $broot_search[1] == . || $broot_search[-2,-1] == /. ]]  show_hidden=--hidden

  # If partial has leading '/', '../', or ~/,
  # set broot start folder (start_dir)
  local start_dir
  if [[ $partial == ~/* ]] {
    start_dir=~
  } else {
    local updirs=${(M)partial##(../|/)##}
    start_dir=${updirs:-.}
  }

  # Collect determined broot arguments
  local broot_args=($show_hidden $start_dir)
  if [[ $broot_search ]]  broot_args+=(--cmd "$broot_search")

  # Get a location (or not) from broot,
  # using select.hjson config
  echoti rmkx
  local locations=(${(f)"$(<$TTY broot-print-files $broot_args)"})

  # Add location to line or restore original partial
  if [[ $locations ]] {

    # If GNU coreutils realpath is present,
    # convert some paths from absolute to relative
    if (( $+commands[realpath] )) {
      if [[ $(realpath --help 2>&1) == *--relative-base* ]] {
        local locations_abs=($locations) loc
        locations=()
        for loc ( $locations_abs )  locations+=("$(realpath --relative-base ~ --relative-to . $loc)")
      }
    }

    # Ensure minimal and sufficient quoting
    locations=(${(q-)locations})

    LBUFFER+="$locations "
  } else {
    LBUFFER+=$partial
  }

  # If using fast-syntax-highlighting, retrigger it
  if (( $+functions[_zsh_highlight] ))  _zsh_highlight

}
zle -N       .zle_insert-path-broot
bindkey '\ep' .zle_insert-path-broot  # alt-p

# disable tree view
.zle_insert-shallow() {
	CMD=':toggle_tree'
	.zle_insert-path-broot
	CMD=''
}
zle -N       .zle_insert-shallow
bindkey '\eP' .zle_insert-shallow  # alt-shift-p

}

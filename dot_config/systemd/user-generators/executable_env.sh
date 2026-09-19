#!/usr/bin/env bash
# Regenerate ~/.config/environment.d/env.conf from vars set in ~/.profile

mkdir -p ~/.config/environment.d
conf=~/.config/environment.d/env.conf

# Run in a clean, non-interactive sh so .profile's own logic runs
# (POSIX sh, since .profile is meant for /bin/sh, not zsh/bash-specific)
env_after=$(sh -c 'source ~/.profile 2>/dev/null || . ~/.profile; env')

{
  while IFS='=' read -r key value; do
    case "$key" in
      PWD|OLDPWD|SHLVL|_|SHELLOPTS|PS1|IFS) continue ;;  # skip shell noise
      "") continue ;;
    esac
    echo "${key}=${value}"
  done <<< "$env_after"
} > "$conf"

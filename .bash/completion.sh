# shellcheck shell=bash
# shellcheck disable=SC2207,SC2155


# Auto-complete for `git ru`, which updates remote from HTTPS to SSH.
_git_ru() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local pos=${COMP_CWORD}
    local remotes="$(git remote show)"
    COMPREPLY=()
    [[ pos -eq 2 ]] && COMPREPLY=( $(compgen -W "$remotes" "$cur") )
}


# Auto-complete for otp(), a macOS-specific helper for generating TOTPs.
_otp() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local pos=${COMP_CWORD}
  COMPREPLY=()
  [[ pos -eq 1 ]] && COMPREPLY=( $(compgen -W "${OTP_KEYS[*]}" "$cur") )
}
complete -F _otp otp

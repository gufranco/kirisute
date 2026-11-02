# shellcheck shell=bash
# shellcheck disable=SC2207

_kirisute() {
  local cur words
  cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ "${cur}" == -* ]]; then
    COMPREPLY=($(compgen -W "--dry-run --info --verify --no-verify --backup --no-backup --recursive --json" -- "${cur}"))
    return
  fi
  words="$(compgen -f -- "${cur}" || true)"
  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    words="rename doctor version help ${words}"
  fi
  COMPREPLY=($(compgen -W "${words}" -- "${cur}"))
}

complete -o filenames -F _kirisute kirisute

# shellcheck shell=bash
# shellcheck disable=SC2207

_kirisute() {
  local cur prev words
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  case "${prev}" in
  --format)
    COMPREPLY=($(compgen -W "cso cso2 zso" -- "${cur}"))
    return
    ;;
  --block)
    COMPREPLY=($(compgen -W "2048 4096 8192 16384" -- "${cur}"))
    return
    ;;
  --lz4-cost)
    COMPREPLY=()
    return
    ;;
  *) ;;
  esac
  if [[ "${cur}" == -* ]]; then
    COMPREPLY=($(compgen -W "--dry-run --info --verify --no-verify --backup --no-backup --recursive --json --format --block --lz4-cost --best" -- "${cur}"))
    return
  fi
  words="$(compgen -f -- "${cur}" || true)"
  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    words="rename compress doctor version help ${words}"
  fi
  COMPREPLY=($(compgen -W "${words}" -- "${cur}"))
}

complete -o filenames -F _kirisute kirisute

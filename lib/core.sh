#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

KIRISUTE_VERSION="1.2.0"

ks_version() {
  printf '%s %s\n' "${KS_PROG}" "${KIRISUTE_VERSION}"
}

ks_say() {
  printf '%s\n' "$1"
}

ks_warning() {
  if ks_ui_err; then
    ks_ui_log WARN "$*"
    return 0
  fi
  ks_say "${KS_PROG}: warning: $*" >&2
}

ks_error() {
  if ks_ui_err; then
    ks_ui_log ERROR "$*"
    return 0
  fi
  ks_say "${KS_PROG}: $*" >&2
}

ks_json_string() {
  printf '%s' "$1" | awk '
    BEGIN { for (i = 1; i < 32; i++) code[sprintf("%c", i)] = sprintf("\\u%04x", i) }
    function escape(s,   r, c, i) {
      r = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") r = r "\\\\"
        else if (c == "\"") r = r "\\\""
        else if (c in code) r = r code[c]
        else r = r c
      }
      return r
    }
    { out = out (NR > 1 ? "\\n" : "") escape($0) }
    END { printf "\"%s\"", out }'
}

ks_plural() {
  if [ "$1" -eq 1 ]; then
    printf '1 %s\n' "$2"
  else
    printf '%s %ss\n' "$1" "$2"
  fi
}

ks_human() {
  awk -v bytes="$1" 'BEGIN {
    if (bytes >= 1073741824) printf "%.1f GiB\n", bytes / 1073741824
    else if (bytes >= 1048576) printf "%.1f MiB\n", bytes / 1048576
    else if (bytes >= 1024) printf "%.1f KiB\n", bytes / 1024
    else if (bytes == 1) print "1 byte"
    else printf "%d bytes\n", bytes
  }'
}

#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

KIRISUTE_VERSION="1.0.0"

ks_version() {
  printf '%s %s\n' "${KS_PROG}" "${KIRISUTE_VERSION}"
}

ks_wrap() {
  awk -v width="${KS_WIDTH}" -v indent="$1" '
    function pad(n,   s) {
      s = ""
      while (n-- > 0) { s = s " " }
      return s
    }
    length($0) <= width { print; next }
    {
      match($0, /^ */)
      n = split($0, word, " ")
      out = substr($0, 1, RLENGTH) word[1]
      for (i = 2; i <= n; i++) {
        if (length(out) + 1 + length(word[i]) > width) {
          print out
          out = pad(indent) word[i]
        } else {
          out = out " " word[i]
        }
      }
      print out
    }'
}

ks_terminal() {
  [ "${KIRISUTE_TERMINAL:-}" = 1 ] || [ -t 1 ]
}

ks_say() {
  ks_sy_text="$2"
  if [ "${#ks_sy_text}" -le "${KS_WIDTH}" ] || ! ks_terminal; then
    printf '%s\n' "${ks_sy_text}"
    return 0
  fi
  printf '%s\n' "${ks_sy_text}" | ks_wrap "$1"
}

ks_warning() {
  ks_say 0 "${KS_PROG}: warning: $*" >&2
}

ks_error() {
  ks_say 0 "${KS_PROG}: $*" >&2
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

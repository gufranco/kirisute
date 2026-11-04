#!/bin/sh

# shellcheck source=SCRIPTDIR/state.sh
. "${KS_LIB:?}/state.sh"

# shellcheck disable=SC2034
ks_ui_set() {
  KS_UI_ACCENT="$1"
  KS_UI_OK="$2"
  KS_UI_WARN="$3"
  KS_UI_ERR="$4"
  KS_UI_MUTED="$5"
  KS_UI_TEXT="$6"
  KS_UI_SURFACE="$7"
  KS_UI_HELP="$8"
}

ks_ui_palette() {
  case "$1" in
  kodougu) ks_ui_set "#F25D94" "#50FA7B" "#FFB86C" "#FF5555" "#6C7086" "#CDD6F4" "#313244" pink ;;
  catppuccin-mocha) ks_ui_set "#CBA6F7" "#A6E3A1" "#FAB387" "#F38BA8" "#6C7086" "#CDD6F4" "#313244" dark ;;
  catppuccin-latte) ks_ui_set "#8839EF" "#40A02B" "#FE640B" "#D20F39" "#8C8FA1" "#4C4F69" "#CCD0DA" light ;;
  dracula) ks_ui_set "#BD93F9" "#50FA7B" "#FFB86C" "#FF5555" "#6272A4" "#F8F8F2" "#44475A" dracula ;;
  nord) ks_ui_set "#88C0D0" "#A3BE8C" "#EBCB8B" "#BF616A" "#4C566A" "#D8DEE9" "#3B4252" dark ;;
  gruvbox) ks_ui_set "#FE8019" "#B8BB26" "#FABD2F" "#FB4934" "#928374" "#EBDBB2" "#3C3836" dark ;;
  tokyo-night) ks_ui_set "#7AA2F7" "#9ECE6A" "#E0AF68" "#F7768E" "#565F89" "#C0CAF5" "#292E42" tokyo-night ;;
  mono) ks_ui_set "" "" "" "" "" "" "" ascii ;;
  *) return 1 ;;
  esac
}

ks_ui_is_colour() {
  case "$1" in
  \#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) return 0 ;;
  *) return 1 ;;
  esac
}

# shellcheck disable=SC2034
ks_ui_setup() {
  if ! ks_ui_palette "${KS_THEME}"; then
    ks_ui_palette mono
    KS_UI_PROBLEM="--theme must be one of ${KS_UI_THEMES}, got: ${KS_THEME}"
    return 1
  fi
  if [ -n "${KS_ACCENT}" ] && ! ks_ui_is_colour "${KS_ACCENT}"; then
    KS_UI_PROBLEM="KODOUGU_ACCENT must be a colour such as #CBA6F7, got: ${KS_ACCENT}"
    return 1
  fi
  if [ -n "${KS_ACCENT}" ]; then
    KS_UI_ACCENT="${KS_ACCENT}"
  fi
  if [ -n "${NO_COLOR:-}" ]; then
    ks_ui_palette mono
  fi
}

ks_ui_forced() {
  [ "${KIRISUTE_TEST_GUM:-}" = 1 ]
}

ks_ui_has_gum() {
  command -v gum >/dev/null 2>&1
}

ks_ui_prompts() {
  ks_ui_forced && return 0
  [ -t 0 ] && [ -t 2 ] && ks_ui_has_gum
}

ks_ui_err() {
  ks_ui_forced && return 0
  [ "${KS_UI_STEP}" = 1 ] && return 0
  [ -t 2 ] && ks_ui_has_gum
}

ks_ui_out() {
  ks_ui_forced && return 0
  [ -t 1 ] && ks_ui_has_gum
}

ks_gum() {
  if [ -n "${KS_UI_TEXT}" ]; then
    CLICOLOR_FORCE=1 gum "$@"
    return
  fi
  gum "$@"
}

ks_ui_ink() {
  ks_ui_colour="$1"
  shift
  if [ -z "${ks_ui_colour}" ]; then
    ks_gum style "$@"
    return
  fi
  ks_gum style --foreground "${ks_ui_colour}" "$@"
}

ks_ui_header() {
  ks_uh_name=$(ks_ui_ink "${KS_UI_ACCENT}" --bold -- "kirisute")
  ks_uh_number=$(ks_version | sed -n '1p')
  ks_uh_number="${ks_uh_number#kirisute }"
  ks_uh_version=$(ks_ui_ink "${KS_UI_MUTED}" -- "${ks_uh_number}")
  ks_uh_tagline=$(ks_ui_ink "${KS_UI_TEXT}" -- "${KS_TAGLINE}")
  ks_uh_top=$(ks_gum join --horizontal "${ks_uh_name}" "  " "${ks_uh_version}")
  ks_uh_body=$(ks_gum join --vertical "${ks_uh_top}" "${ks_uh_tagline}")
  printf '\n' >&2
  ks_gum style --border rounded --border-foreground "${KS_UI_ACCENT}" --padding "0 2" -- "${ks_uh_body}" >&2
  printf '\n' >&2
}

ks_ui_title() {
  printf '\n' >&2
  ks_ui_ink "${KS_UI_ACCENT}" --bold -- "$1" >&2
  printf '\n' >&2
}

ks_ui_titled() {
  if ks_ui_prompts; then
    ks_ui_title "$1"
  fi
}

ks_ui_lower_first() {
  printf '%s\n' "$1" | awk 'NR == 1 { a = substr($0, 1, 1); b = substr($0, 2, 1); if (a != tolower(a) && b != toupper(b)) { $0 = tolower(a) substr($0, 2) } } { print }'
}

ks_ui_log() {
  ks_ul_level="$1"
  ks_ul_text=$(ks_ui_lower_first "$2")
  case "${ks_ul_level}" in
  ERROR) ks_ul_colour="${KS_UI_ERR}" ;;
  WARN) ks_ul_colour="${KS_UI_WARN}" ;;
  *) ks_ul_colour="${KS_UI_OK}" ;;
  esac
  ks_ul_lines=$(printf '%s kirisute: %s\n' "${ks_ul_level}" "${ks_ul_text}" | ks_wrap 2)
  ks_ul_first=$(printf '%s\n' "${ks_ul_lines}" | sed -n '1p')
  ks_ul_rest=$(printf '%s\n' "${ks_ul_lines}" | sed '1d')
  ks_ul_label=$(ks_ui_ink "${ks_ul_colour}" --bold -- "${ks_ul_level}")
  printf '%s%s\n' "${ks_ul_label}" "${ks_ul_first#"${ks_ul_level}"}" >&2
  if [ -n "${ks_ul_rest}" ]; then
    printf '%s\n' "${ks_ul_rest}" >&2
  fi
}

ks_ui_choose() {
  ks_uc_header="$1"
  shift
  ks_gum choose --header "${ks_uc_header}" --cursor "> " --height 14 \
    --cursor.foreground "${KS_UI_ACCENT}" --selected.foreground "${KS_UI_ACCENT}" \
    --header.foreground "${KS_UI_TEXT}" "$@"
}

ks_ui_input() {
  ks_ui_header_text="$1"
  ks_ui_placeholder="$2"
  shift 2
  ks_gum input --header "${ks_ui_header_text}" --placeholder "${ks_ui_placeholder}" --prompt "> " \
    --prompt.foreground "${KS_UI_ACCENT}" --cursor.foreground "${KS_UI_ACCENT}" \
    --header.foreground "${KS_UI_TEXT}" --placeholder.foreground "${KS_UI_MUTED}" "$@"
}

ks_ui_write() {
  ks_gum write --header "$1" --placeholder "$2" --width 72 --height 8 --show-line-numbers \
    --cursor.foreground "${KS_UI_ACCENT}" --header.foreground "${KS_UI_TEXT}" \
    --placeholder.foreground "${KS_UI_MUTED}"
}

ks_ui_confirm() {
  ks_ucf_prompt="$1"
  ks_ucf_yes="$2"
  ks_ucf_no="$3"
  shift 3
  ks_gum confirm "${ks_ucf_prompt}" --affirmative "${ks_ucf_yes}" --negative "${ks_ucf_no}" \
    --prompt.foreground "${KS_UI_TEXT}" --selected.background "${KS_UI_ACCENT}" \
    --unselected.background "${KS_UI_SURFACE}" "$@"
}

ks_ui_summary() {
  ks_us2_pairs=$(($# / 2))
  while [ "${ks_us2_pairs}" -gt 0 ]; do
    ks_us2_label=$(printf '%-7s' "$1")
    ks_us2_label=$(ks_ui_ink "${KS_UI_MUTED}" -- "${ks_us2_label}")
    ks_us2_value=$(ks_ui_ink "${KS_UI_TEXT}" --bold -- "$2")
    shift 2
    set -- "$@" "${ks_us2_label} ${ks_us2_value}"
    ks_us2_pairs=$((ks_us2_pairs - 1))
  done
  printf '\n'
  ks_gum style --border rounded --border-foreground "${KS_UI_MUTED}" --padding "0 1" -- "$@"
  printf '\n'
}

ks_ui_spin() {
  ks_us_title="$1"
  ks_us_log="$2"
  shift 2
  (KS_UI_STEP=1 && "$@") 2>"${ks_us_log}" &
  ks_us_pid=$!
  if ! ks_ui_spin_wait "${ks_us_title}" "${ks_us_pid}"; then
    kill "${ks_us_pid}" 2>/dev/null
    exit 130
  fi
  ks_us_status=0
  wait "${ks_us_pid}" || ks_us_status=$?
  cat "${ks_us_log}" >&2
  return "${ks_us_status}"
}

ks_ui_spin_wait() {
  # shellcheck disable=SC2016
  ks_uw_loop='while kill -0 "$1" 2>/dev/null; do sleep 0.1; done'
  ks_gum spin --spinner dot --spinner.foreground "${KS_UI_ACCENT}" --title.foreground "${KS_UI_TEXT}" --title "$1" -- sh -c "${ks_uw_loop}" _ "$2" >&2
}

ks_ui_table() {
  ks_ut_line="-"
  if [ -n "${KS_UI_TEXT}" ]; then
    ks_ut_line=$(printf '\342\224\200')
  fi
  ks_ut_body=$(ks_ui_table_body "${ks_ut_line}")
  ks_gum style --border rounded --border-foreground "${KS_UI_MUTED}" --padding "0 1" -- "${ks_ut_body}"
}

ks_ui_table_body() {
  awk -F '\t' -v acc="${KS_UI_ACCENT}" -v ok="${KS_UI_OK}" -v warn="${KS_UI_WARN}" \
    -v bad="${KS_UI_ERR}" -v txt="${KS_UI_TEXT}" -v mut="${KS_UI_MUTED}" -v dash="$1" \
    -f "${KS_LIB}/table.awk"
}

ks_ui_done() {
  printf '\n'
  ks_ui_ink "${KS_UI_OK}" --bold -- "$1"
}

ks_ui_badge() {
  ks_ub_colour="$1"
  shift
  if [ -z "${ks_ub_colour}" ]; then
    ks_gum style --bold --underline --padding "0 1" -- "$*"
    return
  fi
  ks_gum style --background "${ks_ub_colour}" --foreground "#1E1E2E" --bold --padding "0 1" -- "$*"
}

ks_ui_chip() {
  if [ -z "${KS_UI_SURFACE}" ]; then
    ks_gum style --padding "0 1" -- "$1"
    return
  fi
  ks_gum style --background "${KS_UI_SURFACE}" --foreground "${KS_UI_TEXT}" --padding "0 1" -- "$1"
}

ks_ui_danger() {
  ks_ud_title=$(ks_ui_ink "${KS_UI_ERR}" --bold -- "$1")
  shift
  ks_gum style --border thick --border-foreground "${KS_UI_ERR}" --padding "0 1" -- "${ks_ud_title}" "$@" >&2
}

ks_ui_markdown() {
  awk '
    NR == 1 {
      split($0, head, " - ")
      printf "# %s\n\n%s\n", head[1], head[2]
      next
    }
    /^[a-z][a-z ]*:$/ {
      if (open) { print "```" }
      printf "\n## %s\n\n```text\n", toupper(substr($0, 1, 1)) substr($0, 2, length($0) - 2)
      open = 1
      next
    }
    { print }
    END { if (open) { print "```" } }
  '
}


#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$HOME/.config/quickshell"

ROSES=(
    rosebar
    roseclip
    roselock
    rosemenu
    rosenotify
    rosepowermenu
    rosewallpapers
    rosewidgets
)

RESET='\033[0m'
PINK='\033[38;5;211m'
PURPLE='\033[38;5;141m'
MUTED='\033[38;5;245m'
GREEN='\033[38;5;114m'
RED='\033[38;5;203m'
WHITE='\033[97m'
BOLD='\033[1m'

line() {
    printf "${MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

banner() {
    clear
    printf "\n${PINK}${BOLD}"
    cat <<'EOF'
       ____                 _____ __         ____
      / __ \___  ________  / ___// /_  ___  / / /
     / /_/ / _ \/ ___/ _ \ \__ \/ __ \/ _ \/ / /
    / _, _/  __(__  )  __/___/ / / / /  __/ / /
   /_/ |_|\___/____/\___/____/_/ /_/\___/_/_/

EOF
    printf "${RESET}\n"
    printf "  ${WHITE}${BOLD}ROSESHELL${RESET} ${MUTED}· INSTALLER${RESET}\n"
    printf "  ${MUTED}quickshell desktop components${RESET}\n\n"
    line
    printf "\n"
}

success() { printf "  ${GREEN}✓${RESET}  %s\n" "$1"; }
failure() { printf "  ${RED}✗${RESET}  %s\n" "$1"; }
info() { printf "  ${PURPLE}◆${RESET}  %s\n" "$1"; }

progress() {
    local current=$1 total=$2
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))

    printf "\r  ${PINK}["
    printf '%*s' "$filled" '' | tr ' ' '█'
    printf '%*s' "$((20 - filled))" '' | tr ' ' '░'
    printf "] ${WHITE}%3d%%${RESET} " "$percent"
}

if ! command -v git >/dev/null 2>&1; then
    printf "${RED}git is required. Install it first.${RESET}\n"
    exit 1
fi

banner

printf "  ${WHITE}Installation target${RESET}\n"
printf "  ${MUTED}%s${RESET}\n\n" "$BASE_DIR"

info "Preparing RoseShell..."
mkdir -p "$BASE_DIR"
success "Installation directory ready"

printf "\n"
line
printf "\n  ${WHITE}${BOLD}INSTALLING COMPONENTS${RESET}\n\n"

INSTALLED=0 UPDATED=0 FAILED=0 SKIPPED=0
TOTAL=${#ROSES[@]}
CURRENT=0

for repo in "${ROSES[@]}"; do
    CURRENT=$((CURRENT + 1))
    DEST="$BASE_DIR/$repo"
    URL="https://github.com/sappyware/$repo.git"

    progress "$CURRENT" "$TOTAL"
    printf "\n  ${WHITE}%-18s${RESET}" "$repo"

    if [[ -d "$DEST/.git" ]]; then
        if git -C "$DEST" pull --ff-only --quiet; then
            printf "${GREEN}updated${RESET}\n"
            UPDATED=$((UPDATED + 1))
        else
            printf "${RED}update failed${RESET}\n"
            FAILED=$((FAILED + 1))
        fi
    elif [[ -e "$DEST" ]]; then
        printf "${RED}directory exists (skipped)${RESET}\n"
        SKIPPED=$((SKIPPED + 1))
    elif git clone --quiet "$URL" "$DEST"; then
        printf "${GREEN}installed${RESET}\n"
        INSTALLED=$((INSTALLED + 1))
    else
        printf "${RED}clone failed${RESET}\n"
        FAILED=$((FAILED + 1))
    fi
done

printf "\n"
line
printf "\n  ${WHITE}${BOLD}INSTALLATION SUMMARY${RESET}\n\n"

success "New installations: $INSTALLED"
success "Updated:           $UPDATED"

(( SKIPPED == 0 )) || info "Skipped:           $SKIPPED"
(( FAILED == 0 )) || failure "Failed:            $FAILED"

printf "\n"
printf "  ${MUTED}Location:${RESET} ${WHITE}%s${RESET}\n" "$BASE_DIR"
printf "\n"
line
printf "\n"

if (( FAILED == 0 )); then
    printf "  ${PINK}${BOLD}ROSESHELL IS READY.${RESET}\n"
else
    printf "  ${RED}${BOLD}INSTALLATION COMPLETED WITH ERRORS.${RESET}\n"
fi

printf "\n  ${MUTED}github.com/sappyware${RESET}\n\n"

(( FAILED == 0 )) || exit 1

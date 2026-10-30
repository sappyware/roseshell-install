
#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$HOME/.config/quickshell"
GITHUB="https://github.com/sappyware"

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

MODE="${1:-install}"

# ── Theme ──────────────────────────────────────────────

RESET='\033[0m'
PINK='\033[38;5;211m'
PURPLE='\033[38;5;141m'
MUTED='\033[38;5;245m'
GREEN='\033[38;5;114m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;222m'
WHITE='\033[97m'
BOLD='\033[1m'

# ── UI ─────────────────────────────────────────────────

line() {
    printf "${MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

banner() {
    printf "\033[2J\033[H"
    printf "${PINK}${BOLD}"
    cat <<'EOF'

       ____                 _____ __         ____
      / __ \___  ________  / ___// /_  ___  / / /
     / /_/ / _ \/ ___/ _ \ \__ \/ __ \/ _ \/ / /
    / _, _/  __(__  )  __/___/ / / / /  __/ / /
   /_/ |_|\___/____/\___/____/_/ /_/\___/_/_/

EOF
    printf "${RESET}"
    printf "  ${WHITE}${BOLD}ROSESHELL${RESET} ${MUTED}· INSTALLER${RESET}\n"
    printf "  ${MUTED}quickshell desktop components${RESET}\n\n"
    line
    printf "\n"
}

success() { printf "  ${GREEN}✓${RESET}  %s\n" "$1"; }
failure() { printf "  ${RED}✗${RESET}  %s\n" "$1"; }
info()    { printf "  ${PURPLE}◆${RESET}  %s\n" "$1"; }
warning() { printf "  ${YELLOW}!${RESET}  %s\n" "$1"; }

progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))

    printf "\r  ${PINK}["
    printf '%*s' "$filled" '' | tr ' ' '█'
    printf '%*s' "$((20 - filled))" '' | tr ' ' '░'
    printf "] ${WHITE}%3d%%${RESET} " "$percent"
}

# ── Counters ───────────────────────────────────────────

INSTALLED=0
UPDATED=0
CURRENT=0
LATEST=0
SKIPPED=0
FAILED=0

# ── Repository handler ─────────────────────────────────

process_repo() {
    local repo="$1"
    local dest="$BASE_DIR/$repo"
    local url="$GITHUB/$repo.git"

    CURRENT=$((CURRENT + 1))

    progress "$CURRENT" "${#ROSES[@]}"
    printf "\n  ${WHITE}%-19s${RESET}" "$repo"

    # Missing repository: clone it
    if [[ ! -d "$dest/.git" ]]; then
        if [[ -e "$dest" ]]; then
            printf "${YELLOW}directory exists${RESET}\n"
            SKIPPED=$((SKIPPED + 1))
            return
        fi

        if git clone --quiet "$url" "$dest"; then
            printf "${GREEN}installed${RESET}\n"
            INSTALLED=$((INSTALLED + 1))
        else
            printf "${RED}clone failed${RESET}\n"
            FAILED=$((FAILED + 1))
        fi

        return
    fi

    # Install mode: leave existing installations alone
    if [[ "$MODE" == "install" ]]; then
        printf "${MUTED}already installed${RESET}\n"
        SKIPPED=$((SKIPPED + 1))
        return
    fi

    # Check remote
    if ! git -C "$dest" fetch --quiet origin; then
        printf "${RED}fetch failed${RESET}\n"
        FAILED=$((FAILED + 1))
        return
    fi

    # Find upstream branch
    local upstream

    if ! upstream=$(git -C "$dest" rev-parse \
        --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null); then
        printf "${YELLOW}no upstream configured${RESET}\n"
        SKIPPED=$((SKIPPED + 1))
        return
    fi

    # Compare local and remote commits
    local ahead behind

    read -r ahead behind < <(
        git -C "$dest" rev-list --left-right --count "HEAD...$upstream"
    )

    # Already synchronized
    if (( ahead == 0 && behind == 0 )); then
        printf "${GREEN}up to date${RESET}\n"
        LATEST=$((LATEST + 1))
        return
    fi

    # Local branch has commits not on GitHub
    if (( ahead > 0 && behind == 0 )); then
        printf "${PURPLE}local commits ($ahead ahead)${RESET}\n"
        SKIPPED=$((SKIPPED + 1))
        return
    fi

    # Histories have diverged
    if (( ahead > 0 && behind > 0 )); then
        printf "${RED}branches diverged${RESET}\n"
        FAILED=$((FAILED + 1))
        return
    fi

    # GitHub is newer
    if (( behind > 0 )); then

        # Never overwrite local changes
        if [[ -n "$(git -C "$dest" status --porcelain)" ]]; then
            printf "${YELLOW}update available, local changes detected${RESET}\n"
            SKIPPED=$((SKIPPED + 1))
            return
        fi

        if git -C "$dest" merge --ff-only --quiet "$upstream"; then
            printf "${GREEN}updated (+$behind commits)${RESET}\n"
            UPDATED=$((UPDATED + 1))
        else
            printf "${RED}update failed${RESET}\n"
            FAILED=$((FAILED + 1))
        fi
    fi
}

# ── Main ───────────────────────────────────────────────

if [[ "$MODE" != "install" && "$MODE" != "update" ]]; then
    printf "${RED}Usage: ./install.sh [install|update]${RESET}\n"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    printf "${RED}Git is required.${RESET}\n"
    exit 1
fi

banner

printf "  ${WHITE}MODE${RESET}       ${PINK}%s${RESET}\n" "${MODE^^}"
printf "  ${WHITE}TARGET${RESET}     ${MUTED}%s${RESET}\n" "$BASE_DIR"
printf "  ${WHITE}COMPONENTS${RESET} ${MUTED}%s${RESET}\n\n" "${#ROSES[@]}"

mkdir -p "$BASE_DIR"

if [[ "$MODE" == "update" ]]; then
    info "Checking GitHub for newer commits..."
else
    info "Preparing RoseShell installation..."
fi

printf "\n"
line
printf "\n  ${WHITE}${BOLD}COMPONENTS${RESET}\n\n"

for repo in "${ROSES[@]}"; do
    process_repo "$repo"
done

# ── Summary ────────────────────────────────────────────

printf "\n"
line
printf "\n  ${WHITE}${BOLD}INSTALLATION SUMMARY${RESET}\n\n"

success "Installed:  $INSTALLED"
success "Updated:    $UPDATED"
success "Up to date: $LATEST"

(( SKIPPED == 0 )) || warning "Skipped:    $SKIPPED"
(( FAILED == 0 )) || failure "Failed:     $FAILED"

printf "\n"
printf "  ${MUTED}Location: %s${RESET}\n" "$BASE_DIR"
printf "\n"
line
printf "\n"

if (( FAILED == 0 )); then
    printf "  ${PINK}${BOLD}ROSESHELL IS READY.${RESET}\n"
else
    printf "  ${RED}${BOLD}SOME COMPONENTS NEED ATTENTION.${RESET}\n"
fi

printf "\n  ${MUTED}github.com/sappyware${RESET}\n\n"

(( FAILED == 0 )) || exit 1

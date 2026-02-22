#!/bin/bash
# Lab Control Dashboard - Core Engine
set -euo pipefail

# --- 1. GLOBAL SETTINGS & LOGGING ---
BASE_DIR="$(dirname "$(realpath "$0")")"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/install.log"
mkdir -p "$LOG_DIR"

# Hata yakalama (Failure Trace)
failure() {
    local lineno=$1 cmd=$2
    [[ -n "${spinner_pid:-}" ]] && kill "$spinner_pid" 2>/dev/null || true
    echo -e "\n\033[0;31m[!] CRITICAL ERROR at line $lineno: '$cmd' failed.\033[0m"
    echo -e "\033[0;33mLast 10 log entries ($LOG_FILE):\033[0m"
    tail -n 10 "$LOG_FILE"
    exit 1
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

# --- 2. UI TOOLS ---
declare -A COLORS=( [RED]='\033[0;31m' [GREEN]='\033[0;32m' [YELLOW]='\033[0;33m' 
                    [BLUE]='\033[0;34m' [CYAN]='\033[0;36m' [BOLD]='\033[1m' [NC]='\033[0m' )

msg() {
    local color="${COLORS[$1]:-${COLORS[NC]}}" text="$2"
    [[ -t 1 ]] && echo -e "${color}${text}${COLORS[NC]}" || echo -e "$text"
}

display_spinner() {
    local pid=$1 hex="0123456789ABCDEF"
    while kill -0 "$pid" 2>/dev/null; do
        local code=""
        for i in {1..12}; do code+="${hex:RANDOM%16:1}"; done
        printf "\r${COLORS[RED]}process@lab:~$ %s > ${COLORS[NC]}" "$code"
        sleep 0.1
    done
    printf "\r%s\r" " "
}

# --- 3. EXECUTION ENGINE ---
execute_function() {
    local func=$selected_function
    echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] START: $func" >> "$LOG_FILE"

    # Background execution with IO redirection
    $func >> "$LOG_FILE" 2>&1 &
    local f_pid=$!
    
    display_spinner "$f_pid" &
    spinner_pid=$!
    
    wait "$f_pid" && local status=0 || local status=$?
    kill "$spinner_pid" 2>/dev/null || true

    if [ $status -eq 0 ]; then
        echo "[SUCCESS] $func" >> "$LOG_FILE"
        return 0
    else
        echo "[FAILED] $func (Exit Code: $status)" >> "$LOG_FILE"
        return $status
    fi
}

# --- 4. NAVIGATION SYSTEM ---
display_header() {
    clear
    msg RED "╔═══════════════════════════════════════════╗"
    msg RED "║          Lab. Control Dashboard           ║"
    msg RED "╚═══════════════════════════════════════════╝"
    echo
}

load_menu_options() {
    grep -E '^[a-zA-Z0-9_-]+\(\)' "$1" | sed 's/().*//' | \
    grep -vE '^(msg|echo_color|failure|display_spinner|execute_function)$'
}

submenu() {
    local setup_file="$1"
    local title=$(basename "$setup_file" .sh)
    source "$setup_file"
    
    while true; do
        display_header
        msg BLUE "${COLORS[BOLD]}$title Module Operations:"
        local options=($(load_menu_options "$setup_file"))
        
        for i in "${!options[@]}"; do
            msg BOLD "$((i+1)). ${options[i]}"
        done
        msg RED "e. Back"

        read -rp $'\n'"$(msg CYAN "Choice: ")" choice
        [[ "$choice" == "e" ]] && break

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            selected_function="${options[$((choice-1))]}"
            msg GREEN ">> Executing $selected_function..."
            execute_function && msg GREEN "✓ Task completed." || msg RED "✗ Task failed."
            read -rp "Press Enter to continue..."
        else
            msg RED "Invalid selection!"; sleep 1
        fi
    done
}

main_menu() {
    [[ -f ".env" ]] && { set -a; source .env; set +a; }

    while true; do
        display_header
        msg BLUE "${COLORS[BOLD]}Main Categories:"
        local menu_files=($(find "$BASE_DIR/bin" -maxdepth 1 -name "*.sh" | sort))
        
        [[ ${#menu_files[@]} -eq 0 ]] && msg YELLOW "Warning: No .sh files found in bin/."

        for i in "${!menu_files[@]}"; do
            msg BOLD "$((i+1)). $(basename "${menu_files[i]}" .sh)"
        done
        msg RED "e. Exit"

        read -rp $'\n'"$(msg CYAN "Choice: ")" choice
        [[ "$choice" == "e" ]] && { msg CYAN "Goodbye!"; exit 0; }

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#menu_files[@]} )); then
            submenu "${menu_files[$((choice-1))]}"
        else
            msg RED "Invalid selection!"; sleep 1
        fi
    done
}

# Start Dashboard
main_menu
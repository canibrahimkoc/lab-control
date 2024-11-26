#!/bin/bash
set -euo pipefail

BASE_DIR="$(dirname "$(realpath "$0")")"
cd "$BASE_DIR" || exit 1

if [ -f ".env" ]; then
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found."
    exit 1
fi

source ~/.bashrc || true

log() {
    local level="$1"
    local message="$2"
    echo -e "[$level] $message" | tee -a "$BASE_DIR/$log_dir/install.log"
}

declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[0;33m'
    [BLUE]='\033[0;34m'
    [MAGENTA]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[0;37m'
    [ORANGE]='\033[38;5;208m'
    [BOLD]='\033[1m'
    [NC]='\033[0m'
)

echo_color() {
    local color="${COLORS[$1]:-${COLORS[NC]}}"
    local text="$2"
    echo -e "${color}${text}${COLORS[NC]}"
}

display_spinner() {
    local pid=$1
    local hex_chars="0123456789ABCDEF"
    local command_prompt="root@core:~$"
    
    while kill -0 $pid 2>/dev/null; do
        local code_line=""
        for ((i=0; i<16; i++)); do
            code_line+="${hex_chars:RANDOM%16:1}"
        done
        printf "\r${COLORS[RED]}%s %s${COLORS[NC]}" "$command_prompt" "$code_line > "
        sleep 0.1
    done
}

execute_function() {
    temp_file=$(mktemp)
    $selected_function > "$temp_file" 2>&1 &
    local func_pid=$!
    display_spinner $func_pid &
    local spinner_pid=$!
    tail -f "$temp_file" | while read -r line; do
        log "INFO" "$line"
    done &
    local tail_pid=$!
    wait $func_pid
    kill $tail_pid
    wait $spinner_pid
    rm "$temp_file"
}

display_header() {
    clear
    echo_color "RED" "╔═══════════════════════════════════════════╗"
    echo_color "RED" "║               Lab. Control                ║"
    echo_color "RED" "╚═══════════════════════════════════════════╝"
    echo
}

load_menu_options() {
    local file="$1"
    local options=()
    if [[ -f "$file" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*\(\) ]]; then
                options+=("${BASH_REMATCH[1]}")
            fi
        done < "$file"
    fi
    echo "${options[@]}"
}

submenu() {
    local setup_file="$1"
    local title=$(basename "$setup_file" .sh)
    source "$setup_file"
    local options=($(load_menu_options "$setup_file"))
    while true; do
        display_header
        echo_color BLUE "${COLORS[BOLD]}$title:"
        for i in "${!options[@]}"; do
            echo_color BOLD "$((i+1)). ${options[i]}"
        done
        echo_color RED "e. Return to Dashboard"
        read -rp $'\n'"$(echo_color CYAN "Enter your choice: ")" choice
        if [[ -z "$choice" ]]; then
            echo_color RED "Please enter a valid choice."
            sleep 1
            continue
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            selected_function="${options[$((choice-1))]}"
            if [[ $(type -t "$selected_function") == function ]]; then
                echo_color GREEN "Command starting..."
                execute_function
                echo_color GREEN "Command completed successfully!"
            else
                echo_color RED "Function $selected_function not found in $setup_file"
            fi
            read -rp $'\nPress Enter to continue...'
        elif [[ "$choice" == "e" ]]; then
            return
        else
            echo_color RED "Invalid choice. Try again."
            sleep 1
        fi
    done
}

main_menu() {
    while true; do
        display_header
        echo_color BLUE "${COLORS[BOLD]}Dashboard:"
        local menu_files=($(find "$BASE_DIR/bin" -maxdepth 1 -type f -name "*.sh" | sort))
        for i in "${!menu_files[@]}"; do
            local menu_name=$(basename "${menu_files[i]}" .sh)
            echo_color BOLD "$((i+1)). $menu_name"
        done
        echo_color RED "e. Exit"
        read -rp $'\n'"$(echo_color CYAN "Enter your choice: ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#menu_files[@]} ]; then
            submenu "${menu_files[$((choice-1))]}"
        elif [[ "$choice" == "e" ]]; then
            echo_color RED "Exiting..."
            exit 0
        else
            echo_color RED "Invalid choice. Try again."
            sleep 1
        fi
    done
}

main_menu

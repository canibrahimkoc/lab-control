#!/bin/bash

# --- Özel Yardımcı Fonksiyonlar (Menüde görünmezler) ---
_load_env() {
    local base_dir
    base_dir="$(dirname "$(realpath "$0")")"
    [[ -f "$base_dir/.env" ]] && source "$base_dir/.env" || { [[ -f "./.env" ]] && source "./.env"; }
}

_status_msg() {
    local color=$1 msg=$2
    case $color in
        "green")  echo -e "\e[0;32m[✓] $msg\e[0m" ;;
        "red")    echo -e "\e[0;31m[X] $msg\e[0m" ;;
        "yellow") echo -e "\e[0;33m[!] $msg\e[0m" ;;
        "blue")   echo -e "\e[0;34m[i] $msg\e[0m" ;;
    esac
}

# --- Dashboard Menüsünde Görünecek Fonksiyonlar ---

git_update() {
    _load_env
    local target_dir="${git_dir:-/opt}"
    [[ ${#git_update[@]} -eq 0 ]] && { _status_msg "red" "git_update array is empty"; return 1; }

    for repo in "${git_update[@]}"; do
        local path="$target_dir/$repo"
        echo -e "\n\e[1;34m>>> Repository: $repo\e[0m"
        if [[ -d "$path/.git" ]]; then
            cd "$path" || continue
            git fetch --all --prune --quiet
            local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
            
            if [[ -n $(git status --porcelain) ]]; then
                _status_msg "yellow" "Auto-committing local changes..."
                git add . && git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M')" --quiet
            fi

            _status_msg "blue" "Syncing $branch..."
            if git pull origin "$branch" --rebase --quiet && git push origin "$branch" --quiet; then
                _status_msg "green" "Success."
            else
                _status_msg "red" "Sync failed."
            fi
            cd - > /dev/null
        fi
    done
}

git_clone() {
    _load_env
    local target_dir="${git_dir:-/opt}"
    for repo in "${git_clone[@]}"; do
        if [[ ! -d "$target_dir/$repo" ]]; then
            _status_msg "blue" "Cloning $repo..."
            git clone "git@github.com:canibrahimkoc/$repo.git" "$target_dir/$repo" && _status_msg "green" "Done."
        else
            _status_msg "yellow" "$repo exists. Skipped."
        fi
    done
}

git_restore() {
    _load_env
    local target_dir="${git_dir:-/opt}"
    for repo in "${git_restore[@]}"; do
        local path="$target_dir/$repo"
        if [[ -d "$path" ]]; then
            _status_msg "yellow" "Cleaning $repo..."
            cd "$path" && rm -rf node_modules .next .turbo .wrangler .vercel dist build && cd - > /dev/null
            _status_msg "green" "Cleaned."
        fi
    done
}
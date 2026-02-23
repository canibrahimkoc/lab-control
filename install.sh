#!/bin/bash
# Lab Control Dashboard
set -euo pipefail

BASE_DIR="$(dirname "$(realpath "$0")")"
GIT_DIR="/opt"
LOG_DIR="$BASE_DIR/logs"
BACKUP_DIR="$BASE_DIR/backup"
LOG_FILE="$LOG_DIR/install.log"
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

GIT_UPDATE_REPOS=("lab-control" "ck-works" "dev-lab" "not-found" "merovingian-ai" "felinance-api")
GIT_CLONE_REPOS=("lab-control" "ck-works" "dev-lab" "not-found" "merovingian-ai" "felinance-api")
GIT_RESTORE_REPOS=("ck-works")
SQLITE_BACKUP_SRC=("/root/.n8n/database.sqlite")

PG_DB_USER="kullanici_adin"
PG_DB_PASSWORD="sifren"
PG_DB_NAME="veritabani_adin"

MARIA_DB_USER="kullanici_adin"
MARIA_DB_PASSWORD="sifren"
MARIA_DB_NAME="veritabani_adin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

trap 'echo -e "\n${RED}[!] CRITICAL ERROR at line $LINENO: $BASH_COMMAND${NC}"; tail -n 5 "$LOG_FILE"; exit 1' ERR

msg() {
    echo -e "${1}${2}${NC}"
}

display_header() {
    clear
    msg "$BLUE" "╔═══════════════════════════════════════════╗"
    msg "$BLUE" "║          Lab Control Dashboard            ║"
    msg "$BLUE" "╚═══════════════════════════════════════════╝"
    echo
}

execute() {
    local cmd="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    {
        echo -e "\n-------------------------------------------"
        echo "[$timestamp] STARTED: $cmd"
        echo -e "-------------------------------------------\n"
    } >> "$LOG_FILE"

    msg "$YELLOW" ">> Çalıştırılıyor: $cmd"

    set +e
    $cmd 2>&1 | tee -a >(sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE")
    local status=${PIPESTATUS[0]}
    set -e

    timestamp=$(date '+%Y-%m-%d %H:%M:%S') 
    if [ "$status" -eq 0 ]; then
        msg "$GREEN" "✓ İşlem başarıyla tamamlandı."
        {
            echo -e "\n-------------------------------------------"
            echo "[$timestamp] SUCCESS: $cmd"
            echo -e "-------------------------------------------\n"
        } >> "$LOG_FILE"
    else
        msg "$RED" "✗ İşlem başarısız oldu (Hata Kodu: $status)."
        {
            echo -e "\n-------------------------------------------"
            echo "[$timestamp] FAILED: $cmd (Exit Code: $status)"
            echo -e "-------------------------------------------\n"
        } >> "$LOG_FILE"
    fi

    read -rp "Devam etmek için Enter'a basın..."
}

# =========================================================================

sys_auto_install() {
    for cmd in sys_update sys_config sys_alias sys_tools sys_typescript sys_python sys_dart sys_github_setup; do 
        $cmd
    done
    msg "$GREEN" "Tüm sistem kurulumları tamamlandı."
}

sys_update() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
    apt-get autoremove -y && apt-get clean
}

sys_config() { msg "$BLUE" "Sistem konfigürasyonları uygulandı."; }

sys_alias() {
    local bsh="$HOME/.bashrc"

    if ! grep -q "alias lab=" "$bsh"; then
        echo "alias lab='source $BASE_DIR/install.sh'" >> "$bsh"
    else
        sed -i "s|alias lab=.*|alias lab='source $BASE_DIR/install.sh'|g" "$bsh"
    fi
    msg "$BLUE" "Alias güncellendi: 'lab' komutu artık anlık değişiklikleri yansıtacak."
}

sys_tools() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y bash sudo openssl openssh-server git wget curl jq tcpdump ffmpeg build-essential \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
        libgdbm-dev libnss3-dev dpkg-dev gcc gnupg libbluetooth-dev libdb-dev libexpat1-dev \
        uuid-dev pkg-config libpq-dev python3-venv python3-pip postgresql postgresql-contrib redis-server
    ldconfig
}

sys_typescript() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    
    if ! command -v node &>/dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
        . "$NVM_DIR/nvm.sh" && nvm install 22
        npm install -g npm pnpm yarn nodemon
        grep -q "NODE_OPTIONS" ~/.bashrc || echo 'export NODE_OPTIONS="--max-old-space-size=32096"' >> ~/.bashrc
    fi
}

sys_python() {
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    if [ ! -d "$PYENV_ROOT" ]; then
        msg "$YELLOW" "pyenv yükleniyor..."
        curl https://pyenv.run | bash
    fi

    if ! grep -q "PYENV_ROOT" ~/.bashrc; then
        {
            echo 'export PYENV_ROOT="$HOME/.pyenv"'
            echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"'
            echo 'eval "$(pyenv init -)"'
        } >> ~/.bashrc
    fi

    eval "$(pyenv init -)"
    
    if ! pyenv versions | grep -q "3.11"; then
        msg "$YELLOW" "Python 3.11 kuruluyor..."
        pyenv install 3.11
    fi

    pyenv global 3.11
    pyenv rehash
    hash -r
    
    local ver=$(python --version 2>&1)
    msg "$GREEN" "Aktif Sürüm: $ver"
}

sys_dart() {
    export PATH="$PATH:/usr/lib/dart/bin"
    if [ ! -f "/usr/lib/dart/bin/dart" ] && ! command -v dart &>/dev/null; then
        rm -f /var/lib/dpkg/lock*
        curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor --yes -o /usr/share/keyrings/dart.gpg
        echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' > /etc/apt/sources.list.d/dart_stable.list
        apt-get update -y && apt-get install -y dart
        grep -q "/usr/lib/dart/bin" ~/.bashrc || echo 'export PATH="$PATH:/usr/lib/dart/bin"' >> ~/.bashrc
    fi
}

sys_github_setup() {
    git config --global pull.rebase false
    git config --global user.name "root"
    git config --global user.email "git@github.com"

    if [ ! -f ~/.ssh/id_rsa ]; then
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
        ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
    fi
    ssh -T git@github.com 2>&1 | head -n 1 || true
}

sqlite_backup() {
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    for file in "${SQLITE_BACKUP_SRC[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$BACKUP_DIR/$(basename "${file%.*}")_$timestamp.${file##*.}"
            msg "$GREEN" "Yedeklendi: $file"
        else
            msg "$YELLOW" "Bulunamadı: $file"
        fi
    done
}

postgresql_backup() {
    local file="$BACKUP_DIR/${PG_DB_NAME}_$(date +"%Y-%m-%d_%H-%M-%S").sql"
    sudo -u postgres pg_dump -U "$PG_DB_USER" -d "$PG_DB_NAME" > "$file"
    msg "$GREEN" "PostgreSQL Yedeklendi: $file"
}

mariadb_backup() {
    local file="$BACKUP_DIR/${MARIA_DB_NAME}_$(date +"%Y-%m-%d_%H-%M-%S").sql"
    mysqldump -u "$MARIA_DB_USER" -p"$MARIA_DB_PASSWORD" "$MARIA_DB_NAME" > "$file"
    msg "$GREEN" "MariaDB Yedeklendi: $file"
}

git_update() {
    for repo in "${GIT_UPDATE_REPOS[@]}"; do
        if [ -d "${GIT_DIR}/${repo}" ] && [ -d "${GIT_DIR}/${repo}/.git" ]; then
            project_name=$(basename "$repo")
            echo "Processing project: $project_name"
            cd "${GIT_DIR}/${repo}" || continue
            remote_url=$(git config --get remote.origin.url || echo "")
            remote_title=$(basename "$(git rev-parse --show-toplevel)")
            if [ -z "$remote_url" ]; then
                echo "Git remote URL not set. Please run 'git remote add origin <URL>'."
                continue
            fi
            current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
            if [ "$current_branch" = "HEAD" ]; then
                current_branch="main"
            fi
            echo "Updating Git repository..."
            if git ls-remote --exit-code --heads origin "$current_branch" >/dev/null 2>&1; then
                echo "Checking remote changes..."
                if ! git fetch --quiet origin "$current_branch"; then
                    echo "Failed to fetch from remote. Check the remote URL."
                    continue
                fi
                LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "")
                REMOTE=$(git rev-parse "origin/$current_branch" 2>/dev/null || echo "")
                if [ -z "$LOCAL" ] || [ -z "$REMOTE" ]; then
                    echo "Failed to get branch information."
                    continue
                fi
                if [ "$LOCAL" != "$REMOTE" ]; then
                    echo "New updates available, pulling changes..."
                    if ! git pull origin "$current_branch"; then
                        echo "Failed to pull updates. Please check local changes."
                        continue
                    fi
                fi
            else
                echo "Remote branch not found. Creating initial commit..."
                if ! git config user.name >/dev/null || ! git config user.email >/dev/null; then
                    echo "Setting Git user information..."
                    git config user.name "root"
                    git config user.email "git@github.com"
                fi
                if ! git add .; then
                    echo "Failed to add files."
                    continue
                fi
                if ! git commit -m "Initial commit"; then
                    echo "Failed to create initial commit."
                    continue
                fi
                if ! git push -u origin "$current_branch"; then
                    echo "Failed to push initial commit to remote repository."
                    continue
                fi
                echo "Initial commit created and pushed successfully."
            fi
            commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
            major_version=$((commit_count / 100))
            minor_version=$(( (commit_count / 10) % 10 ))
            patch_version=$((commit_count % 10))
            version="v${major_version}.${minor_version}.${patch_version}"
            if [[ $(git status --porcelain) ]]; then
                echo "Local changes detected..."
                
                if ! git config user.name >/dev/null || ! git config user.email >/dev/null; then
                    echo "Setting Git user information..."
                    git config user.name "root"
                    git config user.email "git@github.com"
                fi
                if ! rm -f .git/index; then
                    echo "Failed to remove old files."
                    continue
                fi
                if ! git add .; then
                    echo "Failed to add changes."
                    continue
                fi
                if ! git commit -m "$version"; then
                    echo "Failed to create commit."
                    continue
                fi
                if ! git push origin "$current_branch"; then
                    echo "Failed to push changes to remote repository."
                    continue
                fi
                echo "Changes pushed successfully. New version: $remote_title > $version"
            else
                echo "No local changes. Current version: $remote_title > $version"
            fi
            cd - > /dev/null || return
            echo "Finished processing: $project_name"
            echo "----------------------------------------"
        else
            echo "Error: ${GIT_DIR}/${repo} is not a valid Git repository."
        fi
    done
}

git_clone() {
    for repo in "${GIT_CLONE_REPOS[@]}"; do
        if [ ! -d "$GIT_DIR/$repo" ]; then
            echo "Cloning $repo..."
            git clone "git@github.com:canibrahimkoc/$repo.git" "$GIT_DIR/$repo"
            echo "$repo cloned successfully."
        else
            echo "$repo already exists in $GIT_DIR/. Skipping..."
        fi
    done
}

git_restore() {
    for repo in "${GIT_RESTORE_REPOS[@]}"; do
        echo "Cleaning $repo..."
        if [ -d "$GIT_DIR/$repo" ]; then
            cd "$GIT_DIR/$repo" || continue
            find . -type d \( -name "node_modules" -o -name ".next" -o -name ".turbo" -o -name ".wrangler" -o -name ".vercel" -o -name ".contentlayer" \) -exec rm -rf {} +
            # find . -type d \( -name ".git" -o -name ".github" \) -exec rm -rf {} +
            # find . -type f -name ".gitignore" -exec rm -f {} +
            # find . -type f -name "package-lock.json" -exec rm -f {} +
            echo "$repo cleaned successfully."
            cd - > /dev/null || true
        else
            echo "Error: Directory $GIT_DIR/$repo not found."
        fi
    done
}

tracker_journalctl()      { journalctl -f; }
tracker_network_tcpdump() { tcpdump; }
tracker_kernel_dmesg()    { dmesg --follow; }
tracker_network_port()    { ss -tuln; }
tracker_all_connect()     { ss -tnp; }

# =========================================================================

get_module_functions() {
    case "$1" in
        "System")  echo "sys_auto_install sys_update sys_config sys_alias sys_tools sys_typescript sys_python sys_dart sys_github_setup" ;;
        "Backup")  echo "sqlite_backup postgresql_backup mariadb_backup" ;;
        "Github")  echo "git_update git_clone git_restore" ;;
        "Tracker") echo "tracker_journalctl tracker_network_tcpdump tracker_kernel_dmesg tracker_network_port tracker_all_connect" ;;
    esac
}

submenu() {
    local module="$1"
    while true; do
        display_header
        msg "$CYAN" ">> [ $module ] Modülü:"
        local options=($(get_module_functions "$module"))
        
        for i in "${!options[@]}"; do msg "$BOLD" "$((i+1)). ${options[i]}"; done
        msg "$RED" "e. Geri"

        read -rp $'\n'"Seçiminiz: " choice
        [[ "$choice" == "e" ]] && break

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            execute "${options[$((choice-1))]}"
        else
            msg "$RED" "Geçersiz seçim!"; sleep 1
        fi
    done
}

main_menu() {
    local modules=("System" "Backup" "Github" "Tracker")
    while true; do
        display_header
        msg "$CYAN" ">> Ana Kategoriler:"
        
        for i in "${!modules[@]}"; do msg "$BOLD" "$((i+1)). ${modules[i]}"; done
        msg "$RED" "e. Çıkış"

        read -rp $'\n'"Seçiminiz: " choice
        [[ "$choice" == "e" ]] && { msg "$GREEN" "Sistemden çıkılıyor..."; exit 0; }

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#modules[@]} )); then
            submenu "${modules[$((choice-1))]}"
        else
            msg "$RED" "Geçersiz seçim!"; sleep 1
        fi
    done
}

main_menu
#!/bin/bash
# Lab Control Dashboard
set -euo pipefail

BASE_DIR="$(dirname "$(realpath "$0")")"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/install.log"
mkdir -p "$LOG_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

trap 'echo -e "\n${RED}[!] CRITICAL ERROR at line $LINENO: $BASH_COMMAND${NC}"; tail -n 5 "$LOG_FILE"; exit 1' ERR

msg() { echo -e "${1}${2}${NC}"; }

display_header() {
    clear
    msg "$BLUE" "╔═══════════════════════════════════════════╗"
    msg "$BLUE" "║          Lab Control Dashboard            ║"
    msg "$BLUE" "╚═══════════════════════════════════════════╝"
    echo
}

execute() {
    local cmd="$1"
    echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] START: $cmd" >> "$LOG_FILE"
    msg "$YELLOW" ">> Çalıştırılıyor: $cmd\n"
    
    set +e
    $cmd 2>&1 | tee -a "$LOG_FILE"
    local status=${PIPESTATUS[0]}
    set -e

    if [ "$status" -eq 0 ]; then
        echo "[SUCCESS] $cmd" >> "$LOG_FILE"
        msg "$GREEN" "✓ İşlem başarıyla tamamlandı."
    else
        echo "[FAILED] $cmd (Exit Code: $status)" >> "$LOG_FILE"
        msg "$RED" "✗ İşlem başarısız oldu (Hata Kodu: $status)."
    fi
    read -rp "Devam etmek için Enter'a basın..."
}

# --- YARDIMCI FONKSİYONLAR ---

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
    grep -q "alias lab=" "$bsh" || echo "alias lab='/opt/lab-control/install.sh'" >> "$bsh"
    grep -q "alias logs=" "$bsh" || echo "alias logs='journalctl -f'" >> "$bsh"
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
        . "$NVM_DIR/nvm.sh" && nvm install 20
        npm install -g npm pnpm yarn nodemon
        grep -q "NODE_OPTIONS" ~/.bashrc || echo 'export NODE_OPTIONS="--max-old-space-size=32096"' >> ~/.bashrc
    fi
}

sys_python() {
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    command -v pyenv >/dev/null && eval "$(pyenv init -)"

    if ! command -v python3.11 &>/dev/null; then
        [ ! -d "$PYENV_ROOT" ] && curl https://pyenv.run | bash
        pyenv install 3.11 && pyenv global 3.11
        python -m ensurepip --upgrade && pip install --upgrade pip
    fi
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
    mkdir -p "${BACKUP_DIR:-./backup}"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    for file in "${SQLITE_BACKUP_SRC[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "${BACKUP_DIR:-./backup}/$(basename "${file%.*}")_$timestamp.${file##*.}"
        fi
    done
}

postgresql_backup() {
    mkdir -p "${BACKUP_DIR:-./backup}"
    local file="${BACKUP_DIR:-./backup}/${PG_DB_NAME}_$(date +"%Y-%m-%d_%H-%M-%S").sql"
    sudo -u postgres pg_dump -U "$PG_DB_USER" -d "$PG_DB_NAME" > "$file"
}

mariadb_backup() {
    mkdir -p "${BACKUP_DIR:-./backup}"
    local file="${BACKUP_DIR:-./backup}/${MARIA_DB_NAME}_$(date +"%Y-%m-%d_%H-%M-%S").sql"
    mysqldump -u "$MARIA_DB_USER" -p"$MARIA_DB_PASSWORD" "$MARIA_DB_NAME" > "$file"
}

git_update() {
    for repo in "${GIT_UPDATE_REPOS[@]}"; do
        local target="$GIT_DIR/$repo"
        if [ -d "$target/.git" ]; then
            cd "$target" || continue
            local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
            [ "$branch" = "HEAD" ] && branch="main"
            
            git fetch --quiet origin "$branch" || continue
            git pull origin "$branch" || true

            if [[ $(git status --porcelain) ]]; then
                git add .
                git commit -m "Auto-update $(date +%F)"
                git push origin "$branch"
            fi
            cd - > /dev/null || return
        fi
    done
}

git_clone() {
    for repo in "${GIT_CLONE_REPOS[@]}"; do
        [ ! -d "$GIT_DIR/$repo" ] && git clone "git@github.com:canibrahimkoc/$repo.git" "$GIT_DIR/$repo"
    done
}

git_restore() {
    for repo in "${GIT_RESTORE_REPOS[@]}"; do
        [ -d "$GIT_DIR/$repo" ] && find "$GIT_DIR/$repo" -type d \( -name "node_modules" -o -name ".next" -o -name ".turbo" -o -name ".wrangler" -o -name ".vercel" \) -exec rm -rf {} +
    done
}

tracker_journalctl()      { journalctl -f; }
tracker_network_tcpdump() { tcpdump; }
tracker_kernel_dmesg()    { dmesg --follow; }
tracker_network_port()    { ss -tuln; }
tracker_all_connect()     { ss -tnp; }

# --- MENÜ SİSTEMİ ---

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
    [[ -f "$BASE_DIR/.env" ]] && source "$BASE_DIR/.env" || msg "$YELLOW" "UYARI: .env bulunamadı ($BASE_DIR/.env)"
    sleep 1

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
#!/bin/bash
# Lab Control Dashboard - Core Engine (All-in-One Edition)
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
    printf "\r%s\r" "                                   "
}

display_header() {
    clear
    msg RED "╔═══════════════════════════════════════════╗"
    msg RED "║           Lab. Control Dashboard          ║"
    msg RED "╚═══════════════════════════════════════════╝"
    echo
}

# --- 3. MODULE & ROUTER SYSTEM ---
declare -a MODULES=("System" "Backup" "Github" "Tracker")

get_module_functions() {
    case "$1" in
        "System")  echo "sys_auto_install sys_update sys_config sys_alias sys_tools sys_typescript sys_python sys_dart sys_github_setup" ;;
        "Backup")  echo "sqlite_backup postgresql_backup mariadb_backup" ;;
        "Github")  echo "git_update git_clone git_restore" ;;
        "Tracker") echo "tracker_journalctl tracker_network_tcpdump tracker_kernel_dmesg tracker_network_port tracker_all_connect" ;;
    esac
}

is_interactive() {
    [[ "$1" =~ ^(tracker_journalctl|tracker_network_tcpdump|tracker_kernel_dmesg|tracker_network_port|tracker_all_connect|git_update|git_clone|git_restore)$ ]]
}

# --- 4. EXECUTION ENGINE ---
execute_function() {
    local func=$selected_function
    echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] START: $func" >> "$LOG_FILE"

    if is_interactive "$func"; then
        msg YELLOW ">> Running interactive tool. Press Ctrl+C to stop.\n"
        set +e
        $func
        local status=$?
        set -e
        echo "[FINISHED] $func (Exit Code: $status)" >> "$LOG_FILE"
        return 0
    fi

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

# =========================================================================
# --- 5. FUNCTION LIBRARIES ---
# =========================================================================

# --- [ SYSTEM FUNCTIONS ] ---
sys_auto_install() {
    msg CYAN "Full installation pipeline initiated..."
    for cmd in sys_update sys_config sys_alias sys_tools sys_typescript sys_python sys_dart sys_github_setup; do 
        $cmd
    done
    msg GREEN "All systems operational!"
}

sys_update() {
    msg BLUE "Updating system repositories..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
    apt-get autoremove -y && apt-get clean
}

sys_config() { msg BLUE "System configuration applied."; }

sys_alias() {
    msg BLUE "Provisioning system aliases..."
    local bsh="$HOME/.bashrc"
    grep -q "alias lab=" "$bsh" || echo "alias lab='/opt/lab-control/install.sh'" >> "$bsh"
    grep -q "alias logs=" "$bsh" || echo "alias logs='journalctl -f'" >> "$bsh"
    grep -q "alias services=" "$bsh" || echo "alias services='for service in /etc/systemd/system/multi-user.target.wants/*.service; do echo -e \"\n--- \$(basename \$service) ---\"; systemctl status --no-pager \$(basename \$service); sleep 0.5; done'" >> "$bsh"
}

sys_tools() {
    msg BLUE "Installing core dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y bash sudo openssl openssh-server git wget curl jq tcpdump ffmpeg build-essential \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
        libgdbm-dev libnss3-dev dpkg-dev gcc gnupg libbluetooth-dev libdb-dev libexpat1-dev \
        uuid-dev pkg-config libpq-dev python3-venv python3-pip postgresql postgresql-contrib redis-server
    ldconfig
}

sys_typescript() {
    msg BLUE "Validating Node.js environment..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    
    if ! command -v node &>/dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
        . "$NVM_DIR/nvm.sh" && nvm install 20
        npm install -g npm pnpm yarn nodemon
        grep -q "NODE_OPTIONS" ~/.bashrc || echo 'export NODE_OPTIONS="--max-old-space-size=32096"' >> ~/.bashrc
    fi
    msg GREEN "Node: $(node -v) | NPM: v$(npm -v)"
}

sys_python() {
    msg BLUE "Validating Python (Pyenv) environment..."
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    command -v pyenv >/dev/null && eval "$(pyenv init -)"

    if ! command -v python3.11 &>/dev/null; then
        [ ! -d "$PYENV_ROOT" ] && curl https://pyenv.run | bash
        pyenv install 3.11 && pyenv global 3.11
        python -m ensurepip --upgrade && pip install --upgrade pip
    fi
    msg GREEN "Python: $(python3 --version) | Pip: $(pip --version | awk '{print $2}')"
}

sys_dart() {
    msg BLUE "Validating Dart SDK..."
    export PATH="$PATH:/usr/lib/dart/bin"
    local dp="/usr/lib/dart/bin/dart"

    if [ ! -f "$dp" ] && ! command -v dart &>/dev/null; then
        rm -f /var/lib/dpkg/lock*
        curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor --yes -o /usr/share/keyrings/dart.gpg
        echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' > /etc/apt/sources.list.d/dart_stable.list
        apt-get update -y && apt-get install -y dart
        grep -q "/usr/lib/dart/bin" ~/.bashrc || echo 'export PATH="$PATH:/usr/lib/dart/bin"' >> ~/.bashrc
    fi
    msg GREEN "Dart: $(dart --version 2>&1 | awk '{print $4}')"
}

sys_github_setup() {
    msg BLUE "Checking GitHub connectivity..."
    git config --global pull.rebase false
    git config --global user.name "root"
    git config --global user.email "git@github.com"

    if [ ! -f ~/.ssh/id_rsa ]; then
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
        ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
        msg YELLOW "New SSH Key generated."
    fi
    msg GREEN "Git: $(git --version)"
    ssh -T git@github.com 2>&1 | head -n 1 || true
}

# --- [ BACKUP FUNCTIONS ] ---
sqlite_backup() {
    mkdir -p "${BACKUP_DIR:-./backup}"
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    for file in "${SQLITE_BACKUP_SRC[@]}"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            backup_file="${BACKUP_DIR:-./backup}/${filename%.*}_$timestamp.${filename##*.}"
            cp "$file" "$backup_file"
            echo "Yedekleme tamamlandı: $backup_file"
        else
            echo "Dosya bulunamadı: $file"
        fi
    done
}

postgresql_backup() {
    mkdir -p "${BACKUP_DIR:-./backup}"
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    postgresql_backup_file="${BACKUP_DIR:-./backup}/${PG_DB_NAME}_$timestamp.sql"
    sudo -u postgres pg_dump -U "$PG_DB_USER" -d "$PG_DB_NAME" > "$postgresql_backup_file"
    if [ $? -eq 0 ]; then
        echo "PostgreSQL yedekleme tamamlandı: $postgresql_backup_file"
    else
        echo "PostgreSQL yedekleme sırasında bir hata oluştu."
    fi
}

mariadb_backup() {
    mkdir -p "${BACKUP_DIR:-./backup}"
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    mariadb_backup_file="${BACKUP_DIR:-./backup}/${MARIA_DB_NAME}_$timestamp.sql"
    mysqldump -u "$MARIA_DB_USER" -p"$MARIA_DB_PASSWORD" "$MARIA_DB_NAME" > "$mariadb_backup_file"
    if [ $? -eq 0 ]; then
        echo "MariaDB yedekleme tamamlandı: $mariadb_backup_file"
    else
        echo "MariaDB yedekleme sırasında bir hata oluştu."
    fi
}

# --- [ GITHUB FUNCTIONS ] ---
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
                    echo "Failed to fetch from remote."
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
                        echo "Failed to pull updates."
                        continue
                    fi
                fi
            else
                echo "Remote branch not found. Creating initial commit..."
                git config user.name "root"
                git config user.email "git@github.com"
                git add . || continue
                git commit -m "Initial commit" || continue
                git push -u origin "$current_branch" || continue
                echo "Initial commit pushed successfully."
            fi
            commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
            major_version=$((commit_count / 100))
            minor_version=$(( (commit_count / 10) % 10 ))
            patch_version=$((commit_count % 10))
            version="v${major_version}.${minor_version}.${patch_version}"
            if [[ $(git status --porcelain) ]]; then
                echo "Local changes detected..."
                git config user.name "root"
                git config user.email "git@github.com"
                rm -f .git/index || continue
                git add . || continue
                git commit -m "$version" || continue
                git push origin "$current_branch" || continue
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
            echo "$repo cleaned successfully."
        else
            echo "Error: Directory $GIT_DIR/$repo not found."
        fi
    done
}

# --- [ TRACKER FUNCTIONS ] ---
tracker_journalctl()      { journalctl -f; }
tracker_network_tcpdump() { tcpdump; }
tracker_kernel_dmesg()    { dmesg --follow; }
tracker_network_port()    { ss -tuln; }
tracker_all_connect()     { ss -tnp; }

# =========================================================================
# --- 6. NAVIGATION MENUS ---
# =========================================================================

submenu() {
    local module="$1"
    
    while true; do
        display_header
        msg BLUE "${COLORS[BOLD]}[ $module ] Modülü İşlemleri:"
        local options=($(get_module_functions "$module"))
        
        for i in "${!options[@]}"; do
            msg BOLD "$((i+1)). ${options[i]}"
        done
        msg RED "e. Geri"

        read -rp $'\n'"$(msg CYAN "Seçiminiz: ")" choice
        [[ "$choice" == "e" ]] && break

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            selected_function="${options[$((choice-1))]}"
            msg GREEN ">> Executing $selected_function..."
            execute_function && msg GREEN "✓ İşlem tamamlandı." || msg RED "✗ İşlem başarısız oldu."
            read -rp "Devam etmek için Enter'a basın..."
        else
            msg RED "Geçersiz seçim!"; sleep 1
        fi
    done
}

main_menu() {
    if [[ -f "$BASE_DIR/.env" ]]; then
        source "$BASE_DIR/.env"
    else
        msg RED "UYARI: .env dosyası bulunamadı! Yol: $BASE_DIR/.env"
        sleep 2
    fi

    while true; do
        display_header
        msg BLUE "${COLORS[BOLD]}Ana Kategoriler:"
        
        for i in "${!MODULES[@]}"; do
            msg BOLD "$((i+1)). ${MODULES[i]}"
        done
        msg RED "e. Çıkış"

        read -rp $'\n'"$(msg CYAN "Seçiminiz: ")" choice
        [[ "$choice" == "e" ]] && { msg CYAN "Sistemden çıkılıyor..."; exit 0; }

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#MODULES[@]} )); then
            submenu "${MODULES[$((choice-1))]}"
        else
            msg RED "Geçersiz seçim!"; sleep 1
        fi
    done
}

# Start Dashboard
main_menu
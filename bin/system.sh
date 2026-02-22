#!/bin/bash

auto_install() {
    msg CYAN "Full installation pipeline initiated..."
    for cmd in update config alias tools typescript python dart github; do $cmd; done
    msg GREEN "All systems operational!"
}

update() {
    msg BLUE "Updating system repositories..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
    apt-get autoremove -y && apt-get clean
}

config() { msg BLUE "System configuration applied."; }

alias() {
    msg BLUE "Provisioning system aliases..."
    local bsh="$HOME/.bashrc"
    grep -q "alias lab=" "$bsh" || echo "alias lab='/opt/lab-control/install.sh'" >> "$bsh"
    grep -q "alias logs=" "$bsh" || echo "alias logs='journalctl -f'" >> "$bsh"
    grep -q "alias services=" "$bsh" || echo "alias services='for service in /etc/systemd/system/multi-user.target.wants/*.service; do echo -e \"\n--- \$(basename \$service) ---\"; systemctl status --no-pager \$(basename \$service); sleep 0.5; done'" >> "$bsh"
}

tools() {
    msg BLUE "Installing core dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y bash sudo openssl openssh-server git wget curl jq tcpdump ffmpeg build-essential \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
        libgdbm-dev libnss3-dev dpkg-dev gcc gnupg libbluetooth-dev libdb-dev libexpat1-dev \
        uuid-dev pkg-config libpq-dev python3-venv python3-pip postgresql postgresql-contrib redis-server
    ldconfig
}

typescript() {
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

python() {
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

dart() {
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

github() {
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
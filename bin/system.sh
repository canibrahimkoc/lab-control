auto_install() {
    system_config
    packages_tools
    packages_typeScript
    packages_python
    packages_dart
    # packages_php
    packages_labs
    git_config
}

system_update() {
    apt update -y 
    apt upgrade -y 
    apt dist-upgrade -y
    apt autoremove -y 
    apt clean 
    apt autoclean
    source ~/.bashrc || true
}

system_config() {
    # [ ! -f /etc/resolv.conf ] && echo -e "nameserver 1.1.1.1" > /etc/resolv.conf || sed -i '/^nameserver /d' /etc/resolv.conf && echo -e "nameserver 1.1.1.1" >> /etc/resolv.conf
    grep -q "^\s*alias ck=" ~/.bashrc || echo "alias ck='/lab-control/root.sh'" >> ~/.bashrc || true
    grep -q "^\s*alias CK=" ~/.bashrc || echo "alias CK='/lab-control/root.sh'" >> ~/.bashrc || true
    # grep -q "^\s*alias git-update=" ~/.bashrc || echo "alias git-update='for d in /opt/*; do [ -f \"\$d/update.sh\" ] && cd \$d && bash \"\$d/update.sh\"; done'" >> ~/.bashrc
    grep -q "^\s*alias logs=" ~/.bashrc || echo "alias logs='journalctl -f'" >> ~/.bashrc
    grep -q "^\s*alias services=" ~/.bashrc || echo "alias services='for service in /etc/systemd/system/multi-user.target.wants/*.service; do echo -e \"\\n--- \$(basename \$service) ---\"; systemctl status --no-pager \$(basename \$service); sleep 0.5; done'" >> ~/.bashrc
    source ~/.bashrc
}

git_config() {
    git config --global --get http.proxy
    git config --global pull.rebase false
    git config --global user.name "root"
    git config --global user.email "git@github.com"
    mkdir -p ~/.ssh 
    chmod 700 ~/.ssh 
    yes n | ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa 
    chmod 600 ~/.ssh/id_rsa 
    cat /root/.ssh/id_rsa.pub 
    rm -r /root/.ssh/id_rsa.pub 
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 
    ssh -T git@github.com || true
    source ~/.bashrc || true
}

packages_tools() {
    apt-get install -y bash || true
    apt-get install -y sudo || true
    apt-get install -y openssl || true
    apt-get install -y openssh-server || true
    apt-get install -y git || true
    apt-get install -y wget || true
    apt-get install -y curl || true
    apt-get install -y jq || true
    apt-get install -y tcpdump || true
    apt-get install -y ffmpeg || true
    # apt-get install -y neofetch || true
    # apt-get install -y gzip || true
    # apt-get install -y unzip || true
    # apt-get install -y rsync || true
    # apt-get install -y deborphan || true
    # apt-get install -y nmap || true
    # apt-get install -y btop || true
    # apt-get install -y atop || true
    # apt-get install -y htop || true
    # apt-get install -y sqlite3 || true
    # apt-get install -y mariadb-server || true
    # apt-get install -y nginx || true
    # apt-get install -y certbot python3-certbot-nginx || true
    # apt-get install -y ufw || true && ufw allow 'Nginx Full' && ufw allow ssh && ufw enable || true
    apt-get install -y postgresql postgresql-contrib || true
    apt-get install -y redis-server || true
    apt-get install -y build-essential || true 
    apt-get install -y libssl-dev || true 
    apt-get install -y zlib1g-dev || true 
    apt-get install -y libbz2-dev || true 
    apt-get install -y libreadline-dev || true 
    apt-get install -y libsqlite3-dev || true 
    apt-get install -y llvm || true 
    apt-get install -y libncurses5-dev || true 
    apt-get install -y libncursesw5-dev || true 
    apt-get install -y xz-utils || true 
    apt-get install -y tk-dev || true 
    apt-get install -y libxml2-dev || true 
    apt-get install -y libxmlsec1-dev || true 
    apt-get install -y libffi-dev || true 
    apt-get install -y liblzma-dev || true 
    apt-get install -y libgdbm-dev || true 
    apt-get install -y libnss3-dev || true 
    apt-get install -y dpkg-dev || true 
    apt-get install -y gcc || true 
    apt-get install -y gnupg || true 
    apt-get install -y libbluetooth-dev || true 
    apt-get install -y libdb-dev || true 
    apt-get install -y libexpat1-dev || true 
    apt-get install -y uuid-dev || true 
    apt-get install -y pkg-config || true 
    apt-get install -y libpq-dev || true 
    apt-get install -y python3-venv || true
    apt-get install -y python3-pip -y || true
    sudo ldconfig
    source ~/.bashrc || true
}

packages_typeScript() {
    if ! command -v node &>/dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
        . ~/.nvm/nvm.sh
        nvm install 20
        npm install -g npm pnpm yarn nodemon
        echo 'export NODE_OPTIONS="--max-old-space-size=32096"' >> ~/.bashrc
        source ~/.bashrc || true
    else
        echo "Node.js is already installed:"
        node -v
        npm -v
    fi
}

packages_python() {
    if ! command -v python3.11 &>/dev/null; then
        curl https://pyenv.run | bash
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(pyenv init -)"' >> ~/.bashrc
        . ~/.bashrc
        pyenv install 3.11
        pyenv global 3.11
        pyenv exec python -m ensurepip --upgrade
        pyenv exec pip install --upgrade pip
    else
        echo "Python 3.11 is already installed:"
        python3 --version
        pip --version
    fi
}

packages_dart() {
    if ! command -v dart &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y apt-transport-https
        sudo wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
        echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
        sudo apt-get update && sudo apt-get install -y dart
        source ~/.bashrc || true
    else
        echo "Dart is already installed:"
        dart --version
    fi
}

packages_php() {
    if ! command -v php &>/dev/null; then
        sudo apt-get install -y php8.2-fpm php8.2-bcmath php8.2-curl php8.2-intl php8.2-mbstring php8.2-imagick php8.2-xml php8.2-zip php8.2-opcache php8.2-redis php8.2-mysqlnd
        sudo systemctl enable --now php8.2-fpm
        source ~/.bashrc || true
    else
        echo "PHP is already installed:"
        php -v
        php -m
    fi
}
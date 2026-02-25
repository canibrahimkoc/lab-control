## Lab. Control

Lab Control is a comprehensive, interactive Bash-based dashboard designed to streamline the setup, management, and monitoring of development environments. It automates system dependency installations, manages Git repositories across multiple projects, and handles database backups (PostgreSQL, MariaDB, SQLite) through a unified, easy-to-use interface.

- Node.js >= 22.22
- Npm >= 10.9
- Python >= 3.11
- Dart >= 3.5
- Php  >= 8.2

<hr>

#### 🛠️ Install

First, clone the repository to your local machine or target server:

```bash
git clone https://github.com/canibrahimkoc/lab-control
```

Make the script executable and launch the setup process. This will install necessary system tools and configure the global `lab` alias:

```bash
chmod +x install.sh && ./install.sh
```

#### 🔑 WSL (Windows Subsystem for Linux) Setup

If you are running this environment on Windows, follow these steps to perform a clean installation of Debian on WSL:

```bash
wsl --shutdown; wsl --unregister Debian; wsl --install -d Debian
wsl --setdefault Debian; wsl -d Debian -u root
```

Configure WSL to enable `systemd` (required for background services) and set the default user to `root`:

```bash
echo -e "[interop]\nenabled = true\nappendWindowsPath = true\n\n[user]\ndefault = root\n\n[boot]\nsystemd = true" | sudo tee /etc/wsl.conf > /dev/null
```

Apply the changes by shutting down WSL and verifying that `systemd` is active:

```bash
wsl --shutdown; wsl -d Debian --cd /opt -- systemctl status
```

Finally, install essential dependencies, clone the repository directly into the `/opt` directory, and execute the installation script:

```bash
apt-get install -y bash git && git clone https://github.com/canibrahimkoc/lab-control /opt/lab-control && cd /opt/lab-control && chmod +x install.sh && ./install.sh
```

#### 📦 Control

Launch the interactive Lab Control dashboard to navigate through System, Backup, Github, and Tracker modules:

```bash
sudo lab
```

#### 📦 Build

Trigger the setup and configuration process for your system environments and development tools:

```bash
sudo lab build
```

#### 🔄 Update

Fetch the latest changes for all registered Git repositories, update branches automatically, and upgrade system packages:

```bash
sudo lab update
```

#### 🛡️ Backup

Instantly generate timestamped backups for your SQLite, PostgreSQL, and MariaDB databases, safely storing them in the `backup/` directory:

```bash
sudo lab backup
```

#### 🗑️ Uninstall

Clean up environments and remove Lab Control configurations, aliases, and dependencies from your system:

```bash
sudo lab remove
```

#### 📋 Contributing

Contributions, issues, and feature requests are welcome! If you want to improve Lab Control, please fork the repository, create a feature branch, and submit a pull request. Make sure your shell scripts are well-documented and gracefully handle errors.

&nbsp;⢠⣿⣷⡀⠀⢀⣼⣿⡄  </br>
&nbsp;⢸⣿⣿⡇⠀⢸⣿⣿⡇  </br>
&nbsp;⠀⢿⣿⡇⣀⢸⣿⡿⠀  </br>
&nbsp;⣰⣿⣿⣿⣿⣿⣿⣿⣆  </br>
&nbsp;⣿⡟⢻⣿⣿⣿⡟⢻⣿  </br>
&nbsp;⢻⣿⣿⣟⠿⣻⣿⣿⡟  </br>
&nbsp;⠀⠙⠻⠷⠿⠾⠟⠋
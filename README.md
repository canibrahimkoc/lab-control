## CK

Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum is simply dummy text of the printing and typesetting industry.

- Node.js >= 20.10
- Npm >= 10.9
- Python >= 3.11
- Dart >= 3.5

<hr>

#### 🛠️ Install

Lorem Ipsum is simply dummy text of the printing and typesetting industry.

```bash
  git clone git@github.com:canibrahimkoc/CK.git /ck
```

Lorem Ipsum is simply dummy text of the printing.

```bash
  chmod +x ck.sh && ./ck.sh
```

Lorem Ipsum is simply dummy text of the printing.

```bash
  ck
```

#### 📦 Build

Lorem Ipsum is simply dummy text of the printing and typesetting industry.

```bash
  sudo merv build
```

#### 🔄 Update

Lorem Ipsum is simply dummy text of the printing and typesetting industry.

```bash
  sudo merv update
```

#### 🛡️ Backup

Lorem Ipsum is simply dummy text of the printing and typesetting industry.

```bash
  wsl --export Debian "D:\wsl-backup\debian_backup_$(Get-Date -Format yyyyMMdd).tar"
```

#### 🔑 Tunnel

Lorem Ipsum is simply dummy text of the printing and typesetting industry.

```bash
  sudo merv tunnel
```

#### 🗑️ Uninstall

Lorem Ipsum is simply dummy text of the printing and typesetting industry.

```bash
  sudo merv uninstall
```

#### 📋 Contributing

Lorem Ipsum is simply dummy text of the printing and 'typesetting industry'. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged.
 
&nbsp;⢠⣿⣷⡀⠀⢀⣼⣿⡄  </br>
&nbsp;⢸⣿⣿⡇⠀⢸⣿⣿⡇  </br>
&nbsp;⠀⢿⣿⡇⣀⢸⣿⡿⠀  </br>
&nbsp;⣰⣿⣿⣿⣿⣿⣿⣿⣆  </br>
&nbsp;⣿⡟⢻⣿⣿⣿⡟⢻⣿  </br>
&nbsp;⢻⣿⣿⣟⠿⣻⣿⣿⡟  </br>
&nbsp;⠀⠙⠻⠷⠿⠾⠟⠋


# WSL Config
wsl --shutdown; wsl --unregister Debian; wsl --install -d Debian
wsl --setdefault Debian; wsl -d Debian
echo -e "[interop]\nenabled = false\nappendWindowsPath = false\n\n[user]\ndefault = root\n\n[boot]\nsystemd = true" | sudo tee /etc/wsl.conf > /dev/null
wsl --shutdown; wsl -d Debian
cd ~ && systemctl status
apt-get install -y bash git && it clone https://github.com/canibrahimkoc/lab-control opt/lab-control && cd /opt/lab-control && chmod +x root.sh && ./root.sh

# SSH
ssh-keygen -t rsa -b 4096; type $env:USERPROFILE\.ssh\id_rsa.pub | ssh -o StrictHostKeyChecking=no root@IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"; del %USERPROFILE%\.ssh\id_rsa.pub;

#!/bin/bash

# Değişkenlerin tanımlı olduğundan emin olun (Örn: .env veya main script'ten gelir)
git_dir="${git_dir:-/opt/lab-control}"

git_update() {
    # 1. ENV Dosyasını ve Dizileri Zorla Yükle
    # Scriptin çalıştığı klasörü bul ve .env'i çek
    local current_dir="$(dirname "$(realpath "$0")")"
    if [ -f "$current_dir/.env" ]; then
        source "$current_dir/.env"
    elif [ -f "./.env" ]; then
        source "./.env"
    fi

    # 2. Dizi Kontrolü (Hata ayıklama için echo eklendi)
    if [[ ${#git_update[@]} -eq 0 ]]; then
        echo "[!] ERROR: git_update array is still empty!"
        echo "Current dir: $(pwd)"
        return 1
    fi

    # 3. Döngüye Başla
    for repo in "${git_update[@]}"; do
        target_path="${git_dir}/${repo}"
        
        if [ -d "$target_path/.git" ]; then
            echo ">>> Updating: $repo"
            cd "$target_path" || continue
            
            # Git işlemlerini yap
            git fetch --all --prune --quiet
            current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
            
            # Otomatik Commit Mantığı
            if [[ -n $(git status --porcelain) ]]; then
                echo " [+] Local changes found in $repo, committing..."
                git add .
                git commit -m "Auto-update $(date '+%Y-%m-%d %H:%M')" --quiet
            fi

            # Sync
            echo " [↑] Syncing $current_branch..."
            git pull origin "$current_branch" --rebase --quiet
            if git push origin "$current_branch" 2>&1; then
                echo " [✓] $repo updated successfully."
            else
                echo " [X] $repo push failed (Check SSH/Permissions)."
            fi
            
            cd - > /dev/null
        else
            echo " [!] Skipping: $repo (Not a git repository at $target_path)"
        fi
        echo "----------------------------------------"
    done
}
git_clone() {
    for repo in "${git_clone[@]}"; do
        if [ ! -d "$git_dir/$repo" ]; then
            echo " [→] Cloning $repo..."
            mkdir -p "$git_dir"
            git clone "git@github.com:canibrahimkoc/$repo.git" "$git_dir/$repo"
        else
            echo " [i] $repo already exists. Skipping clone."
        fi
    done
}

git_restore() {
    for repo in "${git_restore[@]}"; do
        target_path="$git_dir/$repo"
        if [ -d "$target_path" ]; then
            echo " [!] Cleaning build artifacts in $repo..."
            cd "$target_path" || continue
            # Kritik olmayan klasörleri temizle
            rm -rf node_modules .next .turbo .wrangler .vercel .contentlayer
            echo " [✓] $repo cleaned."
            cd - > /dev/null
        else
            echo " [X] Error: Directory $target_path not found."
        fi
    done
}
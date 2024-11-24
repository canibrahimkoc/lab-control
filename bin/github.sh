all_git_update() {
    for dir in /opt/*/; do
        if [ -d "$dir" ] && [ -d "$dir/.git" ]; then
            project_name=$(basename "$dir")
            echo "Processing project: $project_name"
            cd "$dir"
            git_update
            cd - > /dev/null
            echo "Finished processing: $project_name"
            echo "----------------------------------------"
        fi
    done
}

git_update() {
    second() { echo -e "\033[1;37m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"; }
    error() { echo -e "\033[0;31m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m" >&2; exit 1; }
    success() { echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"; }

    if [ ! -d ".git" ]; then
        error "Bu dizin bir Git deposu değil."
    fi

    remote_url=$(git config --get remote.origin.url || echo "")
    remote_title=$(basename $(git rev-parse --show-toplevel))

    if [ -z "$remote_url" ]; then
        error "Git remote URL ayarlanmamış. Lütfen 'git remote add origin <URL>' komutunu çalıştırın."
    fi

    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    if [ "$current_branch" = "HEAD" ]; then
        current_branch="main"
    fi

    second "Git deposu güncelleniyor..."

    if git ls-remote --exit-code --heads origin $current_branch >/dev/null 2>&1; then
        second "Remote değişiklikler kontrol ediliyor..."
        if ! git fetch --quiet origin $current_branch; then
            error "Uzak depodan veri çekilemedi. Remote URL'yi kontrol edin."
        fi

        LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "")
        REMOTE=$(git rev-parse origin/$current_branch 2>/dev/null || echo "")

        if [ -z "$LOCAL" ] || [ -z "$REMOTE" ]; then
            error "Branch bilgileri alınamadı."
        fi

        if [ "$LOCAL" != "$REMOTE" ]; then
            second "Yeni güncellemeler mevcut, değişiklikler çekiliyor..."
            if ! git pull origin $current_branch; then
                error "Güncellemeler çekilemedi. Lütfen yerel değişiklikleri kontrol edin."
            fi
        fi
    else
        second "Remote branch bulunamadı. İlk commit oluşturuluyor..."
        if ! git config user.name >/dev/null || ! git config user.email >/dev/null; then
            second "Git kullanıcı bilgileri ayarlanıyor..."
            git config user.name "root"
            git config user.email "git@github.com"
        fi
        
        if ! git add .; then
            error "Dosyalar eklenemedi."
        fi
        
        if ! git commit -m "Initial commit"; then
            error "İlk commit oluşturulamadı."
        fi
        
        if ! git push -u origin $current_branch; then
            error "İlk commit uzak depoya gönderilemedi."
        fi
        
        success "İlk commit başarıyla oluşturuldu ve gönderildi."
    fi

    commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    major_version=$((commit_count / 100))
    minor_version=$(( (commit_count / 10) % 10 ))
    patch_version=$((commit_count % 10))

    version="v${major_version}.${minor_version}.${patch_version}"

    if [[ $(git status --porcelain) ]]; then
        second "Yerel değişiklikler tespit edildi..."
        
        if ! git config user.name >/dev/null || ! git config user.email >/dev/null; then
            second "Git kullanıcı bilgileri ayarlanıyor..."
            git config user.name "root"
            git config user.email "git@github.com"
        fi

        if ! rm -f .git/index; then
            error "Eski dosyalar silinemedi."
        fi

        if ! git add .; then
            error "Değişiklikler eklenemedi."
        fi
        
        if ! git commit -m "$version"; then
            error "Commit oluşturulamadı."
        fi
        
        if ! git push origin $current_branch; then
            error "Değişiklikler uzak depoya gönderilemedi."
        fi
        
        success "Değişiklikler başarıyla gönderildi. Yeni versiyon: $remote_title > $version"
    else
        success "Yerel değişiklik yok. Mevcut versiyon: $remote_title > $version"
    fi
}

git_restore() {
    git rm -r --cached /ck && rm -f .git/index && git reset
}

git_clone() {
    local repos=(
        "ck-works"
        "dev-lab"
        "not-found"
        "merovingian-ai"
        "felinance-api"
    )

    for repo in "${repos[@]}"; do
        if [ ! -d "/opt/$repo" ]; then
            echo "Cloning $repo..."
            git clone "git@github.com:canibrahimkoc/$repo.git" "/opt/$repo"
            # if [ -f "/opt/$repo/install.sh" ]; then
            #     echo "Running install script for $repo..."
            #     cd "/opt/$repo" && chmod +x install.sh && ./install.sh
            # fi
        else
            echo "$repo already exists in /opt/. Skipping..."
        fi
    done
}

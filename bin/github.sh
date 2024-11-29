git_update() {
    for repo in "${git_update[@]}"; do
        if [ -d "${git_dir}/${repo}" ] && [ -d "${git_dir}/${repo}/.git" ]; then
            project_name=$(basename "$repo")
            echo "Processing project: $project_name"
            cd "${git_dir}/${repo}" || continue
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
            echo "Error: ${git_dir}/${repo} is not a valid Git repository."
        fi
    done
}

git_clone() {
    for repo in "${git_clone[@]}"; do
        if [ ! -d "$git_dir/$repo" ]; then
            echo "Cloning $repo..."
            git clone "git@github.com:canibrahimkoc/$repo.git" "$git_dir/$repo"
            echo "$repo cloned successfully."
        else
            echo "$repo already exists in $git_dir/. Skipping..."
        fi
    done
}

git_restore() {
    for repo in "${git_restore[@]}"; do
        echo "Cleaning $repo..."
        if [ -d "$git_dir/$repo" ]; then
            cd "$git_dir/$repo" || continue
            find . -type d \( -name "node_modules" -o -name ".next" -o -name ".turbo" -o -name ".wrangler" -o -name ".vercel" -o -name ".contentlayer" \) -exec rm -rf {} +
            # find . -type d \( -name ".git" -o -name ".github" \) -exec rm -rf {} +
            # find . -type f -name ".gitignore" -exec rm -f {} +
            find . -type f -name "package-lock.json" -exec rm -f {} +
            echo "$repo cleaned successfully."
        else
            echo "Error: Directory $git_dir/$repo not found."
        fi
    done
}

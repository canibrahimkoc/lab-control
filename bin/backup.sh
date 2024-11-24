services_backup() {
    mkdir -p backup 
    backup_dir="./backup"
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    DB_USER=""
    DB_PASSWORD=""
    DB_NAME="dify"
    mariadb_backup_file="$backup_dir/${DB_NAME}_$timestamp.sql"
    postgresql_backup_file="$backup_dir/${DB_NAME}_$timestamp.sql"
    files=(
        "/ck/labs/open-webui/backend/data/webui.db"
        "/root/.n8n/database.sqlite"
    )

    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            backup_file="$backup_dir/${filename%.*}_$timestamp.${filename##*.}"
            cp "$file" "$backup_file"
            echo "Yedekleme tamamlandı: $backup_file"
        else
            echo "Dosya bulunamadı: $file"
        fi
    done
    
    sudo -u postgres pg_dump -U $DB_USER -d $DB_NAME > "$postgresql_backup_file"
    if [ $? -eq 0 ]; then
        echo "PostgreSQL yedekleme tamamlandı: $postgresql_backup_file"
    else
        echo "PostgreSQL yedekleme sırasında bir hata oluştu."
    fi

    # mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > "$mariadb_backup_file"
    # if [ $? -eq 0 ]; then
    #     echo "MariaDB yedekleme tamamlandı: $mariadb_backup_file"
    # else
    #     echo "MariaDB yedekleme sırasında bir hata oluştu."
    # fi
}

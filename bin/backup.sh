sqlite_backup() {
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
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
}

postgresql_backup() {
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    postgresql_backup_file="$backup_dir/${DB_NAME}_$timestamp.sql"
    sudo -u postgres pg_dump -U $DB_USER -d $DB_NAME > "$postgresql_backup_file"
    if [ $? -eq 0 ]; then
        echo "PostgreSQL yedekleme tamamlandı: $postgresql_backup_file"
    else
        echo "PostgreSQL yedekleme sırasında bir hata oluştu."
    fi
}

mariadb_backup() {
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    mariadb_backup_file="$backup_dir/${DB_NAME}_$timestamp.sql"
    mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > "$mariadb_backup_file"
    if [ $? -eq 0 ]; then
        echo "MariaDB yedekleme tamamlandı: $mariadb_backup_file"
    else
        echo "MariaDB yedekleme sırasında bir hata oluştu."
    fi
}

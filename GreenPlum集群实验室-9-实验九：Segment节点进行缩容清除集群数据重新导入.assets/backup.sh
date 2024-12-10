#!/bin/bash

# 数据库列表
DATABASES=(
  "backup_test_database"
  "test_database"
  "test_db"
  "gp_sydb"
  "postgres"
)

# 设置数据库连接参数
DB_HOST="Master-a"
DB_PORT="5432"
DB_USER="gpadmin"
#DB_PASS="your_password" # 如果数据库需要密码，请取消注释并填写密码

# 备份文件的前缀
BACKUP_FILE_PREFIX="/home/gpadmin/backup/backup_"

# 开始循环遍历数据库列表
for DB_NAME in "${DATABASES[@]}"; do
    # 如果需要密码，取消注释下一行
    # BACKUP_CMD="pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -F p -f $BACKUP_FILE_PREFIX$DB_NAME.sql --password=$DB_PASS"
    # 使用以下命令代替，不需要密码
    BACKUP_CMD="pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -F p -f $BACKUP_FILE_PREFIX$DB_NAME.sql"

    # 执行备份命令
    echo "Starting backup for database: $DB_NAME"
    $BACKUP_CMD
    if [ $? -eq 0 ]; then
        echo "Backup completed successfully for database: $DB_NAME"
    else
        echo "Backup failed for database: $DB_NAME"
        exit 1
    fi
done

echo "All database backups have been completed."
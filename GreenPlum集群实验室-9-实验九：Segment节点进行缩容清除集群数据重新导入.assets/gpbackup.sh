#!/bin/bash

# 数据库列表
DATABASES=( "backup_test_database" "test_database" "test_db" "gp_sydb" "postgres" )

# Greenplum连接参数
DB_HOST="Master-a"
DB_PORT="5432"
DB_USER="gpadmin"

# 备份目录的根目录
BACKUP_BASE_DIR="/home/gpadmin/backups-Experiment-9/"

# 获取当前日期和时间戳
DATE=$(date +%Y%m%d%H%M%S)

# 遍历数据库列表并备份
for DB_NAME in "${DATABASES[@]}"; do
    # 为每个数据库创建一个包含时间戳的备份目录，并包含数据库名称
    BACKUP_DIR="${BACKUP_BASE_DIR}${DB_NAME}"

    # 使用gpbackup命令进行备份
    echo "Starting backup for database: $DB_NAME"
    gpbackup --dbname "$DB_NAME" --backup-dir "$BACKUP_DIR" --leaf-partition-data

    # 检查备份命令的退出状态
    if [ $? -eq 0 ]; then
        echo "Backup completed successfully for database: $DB_NAME"
    else
        echo "Backup failed for database: $DB_NAME"
        # 删除失败的备份目录
        rm -r "$BACKUP_DIR"
        exit 1  # 备份失败则退出脚本
    fi
done

echo "All database backups have been completed."
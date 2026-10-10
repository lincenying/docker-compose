存放数据库 SQL 文件。MySQL 容器会把本目录挂载到 /app/mysql。
用仓库根目录的 ./restore-db.sh 恢复：
- mysql.sql    -> 容器 dc-db-mysql
- postgre.sql  -> 容器 dc-db-postgres

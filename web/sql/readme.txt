存放数据库 SQL 文件。
MySQL 容器把本目录挂载到 /app/mysql，PostgreSQL 容器把本目录挂载到 /app/postgresql。
用仓库根目录的 ./restore-db.sh 恢复：
- mysql.sql    -> 容器 dc-db-mysql
- postgre.sql  -> 容器 dc-db-postgres

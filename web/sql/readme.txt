存放数据库 SQL 文件。
MySQL 容器把本目录挂载到 /app/mysql，PostgreSQL 容器把本目录挂载到 /app/postgresql。
用仓库根目录的 ./restore-db.sh 恢复：
- mysql.sql    -> 容器 dc-db-mysql
- postgre.sql  -> 容器 dc-db-postgres

用法:
  ./restore-db.sh                 # 恢复目录中存在的 SQL
  ./restore-db.sh mysql           # 只恢复 MySQL
  ./restore-db.sh postgres        # 只恢复 PostgreSQL

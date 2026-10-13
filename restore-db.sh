#!/usr/bin/env bash
# 将 web/sql/mysql.sql、web/sql/postgre.sql 恢复到对应数据库容器
# 兼容 macOS 自带 Bash 3.2
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

SQL_DIR="web/sql"
MYSQL_SQL="${SQL_DIR}/mysql.sql"
POSTGRES_SQL="${SQL_DIR}/postgre.sql"
MYSQL_CONTAINER="dc-db-mysql"
POSTGRES_CONTAINER="dc-db-postgres"

usage() {
  cat <<'EOF'
用法:
  ./restore-db.sh                 恢复目录中存在的 SQL
  ./restore-db.sh mysql           只恢复 MySQL
  ./restore-db.sh postgres        只恢复 PostgreSQL

SQL 文件（放在 web/sql/）:
  mysql.sql     -> 容器 dc-db-mysql
  postgre.sql   -> 容器 dc-db-postgres

库名和密码优先读取正在运行的容器环境变量，否则读取 .env / .env.local，
再否则使用 compose 默认值。MySQL 仅在 full.mongo / full.postgres 中，
PostgreSQL 仅在 postgres / full.postgres 中。

示例:
  ./dc.sh up full.postgres
  ./restore-db.sh
  ./restore-db.sh mysql
  ./restore-db.sh pg
EOF
}

load_env_file() {
  local file="$1" line key value
  [ -f "$file" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in
      ''|\#*) continue ;;
    esac
    key="${line%%=*}"
    value="${line#*=}"
    case "$key" in
      MYSQL_ROOT_PASSWORD|MYSQL_DATABASE|MYSQL_USER|MYSQL_PASSWORD|POSTGRES_USER|POSTGRES_PASSWORD|POSTGRES_DB) ;;
      *) continue ;;
    esac
    case "$value" in
      \"*\") value="${value#\"}"; value="${value%\"}" ;;
      \'*\') value="${value#\'}"; value="${value%\'}" ;;
    esac
    printf -v "$key" '%s' "$value"
    export "$key"
  done < "$file"
}

load_db_env() {
  load_env_file .env
  load_env_file .env.local
}

prefer_container_env() {
  local container="$1" key="$2" value
  value="$(docker exec "$container" printenv "$key" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    printf -v "$key" '%s' "$value"
    export "$key"
  fi
}

assert_ident() {
  local name="$1" label="$2"
  case "$name" in
    [A-Za-z_][A-Za-z0-9_]*) ;;
    *)
      echo "错误: ${label}「${name}」含有不支持的字符" >&2
      exit 1
      ;;
  esac
}

require_sql() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "错误: 找不到 ${file}" >&2
    exit 1
  fi
  if [ ! -s "$file" ]; then
    echo "错误: ${file} 是空文件" >&2
    exit 1
  fi
}

require_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "错误: 无法连接 Docker，请先启动 Docker" >&2
    exit 1
  fi
}

container_running() {
  local state
  state="$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || true)"
  [ "$state" = "true" ]
}

require_container() {
  local container="$1" hint="$2"
  if ! container_running "$container"; then
    echo "错误: 容器 ${container} 未运行。请先执行: ${hint}" >&2
    exit 1
  fi
}

wait_mysql() {
  local i=0
  echo "等待 MySQL 就绪..."
  while [ "$i" -lt 60 ]; do
    if docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" \
      mysqladmin ping -uroot --silent >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  echo "错误: MySQL 在 60 秒内未就绪" >&2
  exit 1
}

wait_postgres() {
  local i=0
  echo "等待 PostgreSQL 就绪..."
  while [ "$i" -lt 60 ]; do
    if docker exec "$POSTGRES_CONTAINER" \
      pg_isready -U "$POSTGRES_USER" -d postgres >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  echo "错误: PostgreSQL 在 60 秒内未就绪" >&2
  exit 1
}

restore_mysql() {
  require_sql "$MYSQL_SQL"
  require_container "$MYSQL_CONTAINER" "./dc.sh up full.postgres 或 ./dc.sh up full.mongo"
  prefer_container_env "$MYSQL_CONTAINER" MYSQL_ROOT_PASSWORD
  prefer_container_env "$MYSQL_CONTAINER" MYSQL_DATABASE
  : "${MYSQL_ROOT_PASSWORD:=rootpassword}"
  : "${MYSQL_DATABASE:=database_name}"
  assert_ident "$MYSQL_DATABASE" "MySQL 数据库名"
  wait_mysql

  echo "确保数据库 ${MYSQL_DATABASE} 存在..."
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" \
    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

  echo "==> 恢复 ${MYSQL_SQL} -> ${MYSQL_CONTAINER} / ${MYSQL_DATABASE}"
  docker exec -i -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" \
    mysql -uroot --default-character-set=utf8mb4 "$MYSQL_DATABASE" < "$MYSQL_SQL"
  echo "MySQL 恢复完成"
}

restore_postgres() {
  local exists
  require_sql "$POSTGRES_SQL"
  require_container "$POSTGRES_CONTAINER" "./dc.sh up postgres 或 ./dc.sh up full.postgres"
  prefer_container_env "$POSTGRES_CONTAINER" POSTGRES_USER
  prefer_container_env "$POSTGRES_CONTAINER" POSTGRES_PASSWORD
  prefer_container_env "$POSTGRES_CONTAINER" POSTGRES_DB
  : "${POSTGRES_USER:=postgres}"
  : "${POSTGRES_PASSWORD:=POSTGRES_password}"
  : "${POSTGRES_DB:=database_name}"
  assert_ident "$POSTGRES_USER" "PostgreSQL 用户名"
  assert_ident "$POSTGRES_DB" "PostgreSQL 数据库名"
  wait_postgres

  exists="$(docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_CONTAINER" \
    psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB}'")"
  if [ "$exists" != "1" ]; then
    echo "创建数据库 ${POSTGRES_DB}..."
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_CONTAINER" \
      psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 \
      -c "CREATE DATABASE ${POSTGRES_DB}"
  fi

  # Navicat 会先单独 DROP/CREATE identity 序列，列仍占用该序列时 DROP 会失败；
  # 建表里的 GENERATED AS IDENTITY 会再建同名序列，末尾的 OWNED BY 也不能改 identity 序列属主。
  # 因此去掉这段前置序列定义，以及对应的 ALTER SEQUENCE ... OWNED BY。
  pause_postgres_api
  trap resume_postgres_api EXIT
  reset_postgres_public

  echo "==> 恢复 ${POSTGRES_SQL} -> ${POSTGRES_CONTAINER} / ${POSTGRES_DB}"
  filter_postgres_identity_sequences "$POSTGRES_SQL" \
    | docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_CONTAINER" \
      psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"
  echo "PostgreSQL 恢复完成"
}

# 暂停正在跑的 API，避免恢复过程中 Drizzle 把 public 表再建回来
pause_postgres_api() {
  local running paused
  paused_postgres_api=0
  running="$(docker inspect -f '{{.State.Running}}' dc-api-bun-postgre 2>/dev/null || true)"
  paused="$(docker inspect -f '{{.State.Paused}}' dc-api-bun-postgre 2>/dev/null || true)"
  if [ "$running" = "true" ] && [ "$paused" != "true" ]; then
    echo "暂停 dc-api-bun-postgre，避免恢复期间改写数据库..."
    docker pause dc-api-bun-postgre
    paused_postgres_api=1
  fi
}

resume_postgres_api() {
  if [ "${paused_postgres_api:-0}" -eq 1 ]; then
    docker unpause dc-api-bun-postgre >/dev/null 2>&1 || true
    paused_postgres_api=0
  fi
}

reset_postgres_public() {
  echo "清空 ${POSTGRES_DB} 的 public schema..."
  docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$POSTGRES_CONTAINER" \
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'SQL'
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid();
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT ALL ON SCHEMA public TO CURRENT_USER;
SQL
}

# 去掉与 GENERATED AS IDENTITY 冲突的前置序列定义（Navicat）
filter_postgres_identity_sequences() {
  awk '
    FNR == NR {
      if ($0 ~ /^CREATE TABLE "/) {
        table = $0
        sub(/^CREATE TABLE "[^"]+"\."/, "", table)
        sub(/".*/, "", table)
      }
      if ($0 ~ /GENERATED[[:space:]]+(BY[[:space:]]+DEFAULT|ALWAYS)[[:space:]]+AS[[:space:]]+IDENTITY/) {
        col = $0
        sub(/^[[:space:]]*"/, "", col)
        sub(/".*/, "", col)
        if (table != "" && col != "") {
          ident[table "_" col "_seq"] = 1
        }
      }
      next
    }
    /^DROP SEQUENCE IF EXISTS "/ {
      seq = $0
      sub(/^DROP SEQUENCE IF EXISTS "[^"]+"\."/, "", seq)
      sub(/".*/, "", seq)
      if (seq in ident) {
        skip = 1
        next
      }
    }
    skip && /^ALTER SEQUENCE / && /OWNER TO/ {
      skip = 0
      next
    }
    skip { next }
    /^ALTER SEQUENCE "/ {
      seq = $0
      sub(/^ALTER SEQUENCE "[^"]+"\."/, "", seq)
      sub(/".*/, "", seq)
      if (seq in ident) {
        if (getline nextline <= 0) next
        if (nextline ~ /OWNED BY/) next
        print
        print nextline
        next
      }
    }
    { print }
  ' "$1" "$1"
}

main() {
  local arg want_mysql=0 want_postgres=0

  if [ "$#" -eq 0 ]; then
    if [ -f "$MYSQL_SQL" ]; then
      want_mysql=1
    fi
    if [ -f "$POSTGRES_SQL" ]; then
      want_postgres=1
    fi
    if [ "$want_mysql" -eq 0 ] && [ "$want_postgres" -eq 0 ]; then
      echo "错误: ${SQL_DIR} 下没有 mysql.sql 或 postgre.sql" >&2
      usage >&2
      exit 1
    fi
  else
    for arg in "$@"; do
      case "$arg" in
        help|-h|--help)
          usage
          exit 0
          ;;
        mysql|my)
          want_mysql=1
          ;;
        postgres|postgre|pg)
          want_postgres=1
          ;;
        *)
          echo "错误: 未知参数「${arg}」" >&2
          usage >&2
          exit 1
          ;;
      esac
    done
  fi

  if [ "$want_mysql" -eq 1 ]; then
    require_sql "$MYSQL_SQL"
  fi
  if [ "$want_postgres" -eq 1 ]; then
    require_sql "$POSTGRES_SQL"
  fi

  load_db_env
  require_docker

  if [ "$want_mysql" -eq 1 ]; then
    restore_mysql
  fi
  if [ "$want_postgres" -eq 1 ]; then
    restore_postgres
  fi
}

main "$@"

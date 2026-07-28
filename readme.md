# docker-compose

多容器编排：Nginx 反代 + API + 前端（Vue3 SSR / Nuxt）+ 可选 PHP / 数据库。

## 选择哪个 compose 文件

| Compose 文件 | Nginx 配置目录 | 数据库 | 适用场景 |
|---|---|---|---|
| `docker-compose.yml` | `nginx/conf.d`（反代宿主机端口） | 无 | 仅启动 Nginx；后端需已在宿主机运行 |
| `docker-compose.prod.yml` | `nginx/conf.d.alias` | Mongo | 生产：API + Vue/Nuxt（无 PHP） |
| `docker-compose.full.yml` | `nginx/conf.d.alias` | Mongo + MySQL | 全栈：上者 + PHP |
| `docker-compose.postgres.yml` | `nginx/conf.d.alias.postgres` | Postgres | Postgres API + Vue/Nuxt（无 PHP） |
| `docker-compose.full.postgres.yml` | `nginx/conf.d.alias.postgres` | Postgres + MySQL | Postgres 栈 + PHP |

**不要混用**：Mongo 栈用 `conf.d.alias`（`dc-api-express:4000`）；Postgres 栈用 `conf.d.alias.postgres`（`dc-api-bun-postgre:4080`）。compose 已按文件挂载对应目录。

## 启动命令

推荐使用 `./dc.sh`（自动加载 `.env` + `.env.local`，兼容 5 个 compose 文件）：

```bash
./dc.sh                          # 交互菜单
./dc.sh list                     # 查看可用 stack
./dc.sh up nginx                 # 仅 Nginx
./dc.sh up prod                  # Mongo 栈（无 PHP）
./dc.sh up full                  # Mongo + MySQL + PHP
./dc.sh up postgres              # Postgres 栈（无 PHP）
./dc.sh up full.postgres         # Postgres + MySQL + PHP
./dc.sh down full.postgres
./dc.sh logs postgres
./dc.sh ps full
```

也可直接使用 docker compose（需自行带上 env 文件）：

```bash
# 仅 Nginx（依赖宿主机上的后端端口）
docker compose --env-file .env --env-file .env.local -f docker-compose.yml up -d

# Mongo 栈（无 PHP）
docker compose --env-file .env --env-file .env.local -f docker-compose.prod.yml up -d

# Mongo + MySQL + PHP 全栈
docker compose --env-file .env --env-file .env.local -f docker-compose.full.yml up -d

# Postgres 栈（无 PHP）
docker compose --env-file .env --env-file .env.local -f docker-compose.postgres.yml up -d

# Postgres + MySQL + PHP 全栈
docker compose --env-file .env --env-file .env.local -f docker-compose.full.postgres.yml up -d
```

## 域名与可达性

需将下列域名解析到服务器（或写入 `/etc/hosts`）。当前 SSL 未启用，请用 **HTTP :80** 访问。

| 域名 | prod / full (Mongo) | postgres / full.postgres | 仅 nginx (`conf.d`) |
|---|---|---|---|
| `api.test.com` | 可访问 → `dc-api-express:4000` | 可访问 → `dc-api-bun-postgre:4080` | 需宿主机 `:4008` |
| `www.test.com` | 可访问（SSR + `/api/`） | 可访问（SSR + `/api/`） | 需宿主机 `:7777` / `:4008` |
| `nuxt.test.com` | 可访问 | 可访问 | 需宿主机 `:7200` |
| `demo-web.test.com` / `demo-admin.test.com` | 静态可访问 | 静态可访问 | 静态可访问 |
| `demo-h5.test.com` / `demo-uniapp.test.com` | 静态 + `/api/` | 静态 + `/api/` | 静态；`/api/` 需宿主机 `:4008` |
| `php.test.com` | 仅 **full** / **full.postgres** | 仅 **full.postgres** | 不可用（无 app-php） |
| `py.test.com` | 无（仅 `conf.d`） | 无 | 需宿主机 `:8006` |

## 环境变量

- `.env`：镜像 tag 等可提交配置
- `.env.local`：密码、数据目录等私密配置（已 gitignore；`./dc.sh` 会自动加载）

```bash
# .env
API_EXPRESS_TAG=1.26.0727
API_POSTGRES_TAG=1.26.0728
APP_VUE3_SSR_TAG=1.26.0727
APP_NUXT_TAG=1.26.0727
APP_PHP_TAG=1.26.0727

# .env.local（示例）
MONGO_DIR=mongodb数据库路径
MYSQL_DIR=mysql数据库路径
POSTGRES_DIR=postgresql数据库路径

# 如果是初始化新的数据库, 密码可随意设置, 如果数据库路径已经有数据, 需设置成之前初始化时的密码
POSTGRES_HOST=POSTGRES主机地址,默认值:postgres
POSTGRES_PORT=POSTGRES主机端口,默认值:5432
POSTGRES_DB=POSTGRES数据库名,默认值:database_name
POSTGRES_USER=POSTGRES数据库用户名,默认值:postgres
POSTGRES_PASSWORD=POSTGRES密码,默认值:POSTGRES_password

MYSQL_ROOT_PASSWORD=mysqlroot密码,默认值:rootpassword
MYSQL_DATABASE=mysql数据库名,默认值:database_name
MYSQL_USER=mysql数据库用户名,默认值:MYSQL_user
MYSQL_PASSWORD=mysql数据库密码,默认值:MYSQL_password
```

换机器部署时修改 `MONGO_DIR` / `MYSQL_DIR` / `POSTGRES_DIR`。未设置时默认分别为 `./data/mongodb`、`./data/mysqldb`、`/var/lib/postgresql`。

`POSTGRES_HOST` `POSTGRES_PORT` `POSTGRES_DB` `POSTGRES_USER` `POSTGRES_PASSWORD`
`MYSQL_ROOT_PASSWORD` `MYSQL_DATABASE` `MYSQL_USER` `MYSQL_PASSWORD`
未设置时, 默认值分别是:
`postgres`, `5432`, `database_name`, `postgres`, `POSTGRES_password`,
`rootpassword`, `database_name`, `MYSQL_user`, `MYSQL_password`

## 开启 PHP 项目

### 数据库

在 `.env.local` 中设置 `MYSQL_DIR` 与 `MYSQL_*`。`mysql` 与 `app-php` 共用：

```bash
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=database_name
MYSQL_USER=MYSQL_user
MYSQL_PASSWORD=MYSQL_password
```

`app-php` 的 `DB_DATABASE` / `DB_USERNAME` / `DB_PASSWORD` 分别映射自 `MYSQL_DATABASE` / `MYSQL_USER` / `MYSQL_PASSWORD`。

若使用外部数据库，可删除 compose 中的 `mysql` 服务，并改 PHP 应用内数据库配置。

### 启动后初始化（full / full.postgres）

```bash
# 进入 mysql 容器恢复数据（若有 ./web/mysql.sql）
docker exec -it dc-db-mysql /bin/bash
mysql -uuser -p database_name < /home/mysql/mysql.sql

```

## Nginx 配置说明

- `nginx/conf.d`：反代 `host.docker.internal`（适合仅起 Nginx、后端在宿主机）。
- `nginx/conf.d.alias`：反代 Docker 容器名（Mongo API `dc-api-express:4000`）。
- `nginx/conf.d.alias.postgres`：反代 Postgres API `dc-api-bun-postgre:4080`。

证书放在 `nginx/cert`；当前各站点的 `listen 443 ssl` 仍为注释状态。

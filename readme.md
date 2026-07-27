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

**不要混用**：Mongo 栈用 `conf.d.alias`（`dc-api-server:4000`）；Postgres 栈用 `conf.d.alias.postgres`（`api-bun-server-postgre:4080`）。compose 已按文件挂载对应目录。

## 启动命令

```bash
# 仅 Nginx（依赖宿主机上的后端端口）
docker compose -f docker-compose.yml up -d

# Mongo 栈（无 PHP）
docker compose -f docker-compose.prod.yml up -d

# Mongo + MySQL + PHP 全栈
docker compose -f docker-compose.full.yml up -d

# Postgres 栈（无 PHP）
docker compose -f docker-compose.postgres.yml up -d

# Postgres + MySQL + PHP 全栈
docker compose -f docker-compose.full.postgres.yml up -d
```

## 域名与可达性

需将下列域名解析到服务器（或写入 `/etc/hosts`）。当前 SSL 未启用，请用 **HTTP :80** 访问。

| 域名 | prod / full (Mongo) | postgres / full.postgres | 仅 nginx (`conf.d`) |
|---|---|---|---|
| `api.test.com` | 可访问 → `dc-api-server:4000` | 可访问 → `api-bun-server-postgre:4080` | 需宿主机 `:4008` |
| `www.test.com` | 可访问（SSR + `/api/`） | 可访问（SSR + `/api/`） | 需宿主机 `:7777` / `:4008` |
| `nuxt.test.com` | 可访问 | 可访问 | 需宿主机 `:7200` |
| `demo-web.test.com` / `demo-admin.test.com` | 静态可访问 | 静态可访问 | 静态可访问 |
| `demo-h5.test.com` / `demo-uniapp.test.com` | 静态 + `/api/` | 静态 + `/api/` | 静态；`/api/` 需宿主机 `:4008` |
| `php.test.com` | 仅 **full** / **full.postgres** | 仅 **full.postgres** | 不可用（无 app-php） |
| `py.test.com` | 无（仅 `conf.d`） | 无 | 需宿主机 `:8006` |

## 环境变量（`.env`）

```bash
API_POSTGRES_TAG=1.25.1029
API_EXPRESS_TAG=1.25.1029
APP_VUE3_SSR_TAG=1.25.1029
APP_NUXT_TAG=1.25.1029
APP_PHP_TAG=1.25.1029

MONGO_DIR=/Users/lincenying/web/mongodb/data
MYSQL_DIR=/Users/lincenying/web/mysqldb
POSTGRES_DIR=/Users/lincenying/web/postgresql/data
POSTGRES_PASSWORD=POSTGRESPassword
```

换机器部署时修改 `MONGO_DIR` / `MYSQL_DIR` / `POSTGRES_DIR`。未设置时默认分别为 `./data/mongodb`、`./data/mysqldb`、`/var/lib/postgresql`。

## 开启 PHP 项目

### 数据库

在 `.env` 中设置 `MYSQL_DIR`。`full` / `full.postgres` 中 MySQL 环境变量：

```yaml
MYSQL_ROOT_PASSWORD: rootpassword
MYSQL_DATABASE: cyxiaowu
MYSQL_USER: user
MYSQL_PASSWORD: password
```

与 `app-php` 的 `DB_*` 保持一致。

若使用外部数据库，可删除 compose 中的 `mysql` 服务，并改 PHP 应用内数据库配置。

### 启动后初始化（full / full.postgres）

```bash
# 进入 mysql 容器恢复数据（若有 ./web/demo-php/mysql.sql）
docker exec -it dc-db-mysql /bin/bash
mysql -uuser -p cyxiaowu < /home/mysql/mysql.sql

```

## Nginx 配置说明

- `nginx/conf.d`：反代 `host.docker.internal`（适合仅起 Nginx、后端在宿主机）。
- `nginx/conf.d.alias`：反代 Docker 容器名（Mongo API `dc-api-server:4000`）。
- `nginx/conf.d.alias.postgres`：反代 Postgres API `api-bun-server-postgre:4080`。

证书放在 `nginx/cert`；当前各站点的 `listen 443 ssl` 仍为注释状态。

## 2026-08-03 09:27:41

- 修复 `full.postgres` 启动 `dc-nginx` 失败：Docker Desktop virtiofs 在「目录挂载 + 单文件叠加」时要求目标文件已存在，于 `conf.d.alias` 补齐 `php.conf`、`demo-h5.conf`、`demo-uniapp.conf` 占位文件
- 同步 README 中 Nginx 配置目录说明

commit message: `fix: 修复 nginx 叠加挂载失败`

## 2026-07-28 11:15:47

- 新增 `dc.sh`：兼容 5 套 compose，自动加载 `.env` + `.env.local`
- 私密配置（密码、数据目录等）从 `.env` 迁出到 `.env.local`
- Postgres API 环境变量统一为 `POSTGRES_*`；占位默认值脱敏
- 注释挂载 `api-bun-postgre.production.yaml`，改为由环境变量覆盖配置
- 更新 README / editorconfig（含 `*.sh`）

commit message: `feat: 新增 dc.sh 并将私密配置迁移到 .env.local`

## 2026-07-28 09:31:38

将 `nginx/conf.d.alias`中的内网 `proxy_pass` 从 `container_name` 统一改为 docker-compose `service name`：

- `dc-api-express` / `dc-api-bun-postgre` → `api`
- `dc-app-vue3-ssr` → `app`
- `dc-app-nuxt` → `nuxt`
- `nginx_php`、`api`（postgres 栈已正确）保持不变

commit message: `refactor: nginx 内网转发改用 compose service name`

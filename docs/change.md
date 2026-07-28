## 2026-07-28 09:31:38

将 `nginx/conf.d.alias` 与 `nginx/conf.d.alias.postgres` 中的内网 `proxy_pass` 从 `container_name` 统一改为 docker-compose `service name`：

- `dc-api-express` / `dc-api-bun-postgre` → `api`
- `dc-app-vue3-ssr` → `app`
- `dc-app-nuxt` → `nuxt`
- `nginx_php`、`api`（postgres 栈已正确）保持不变

commit message: `refactor: nginx 内网转发改用 compose service name`

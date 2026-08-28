## 2026-08-27 12:47:59

- Nginx 全局 `client_max_body_size` 调整为 20m，PHP 站点同步为 20M
- full 栈（mongo / postgres）将 `config/php.ini` 只读挂载到 PHP 容器，与 Nginx 请求体上限对齐（`upload_max_filesize` / `post_max_size` 均为 20M）

commit message: `chore: 统一 nginx 与 PHP 请求体上限为 20M`

## 2026-08-21 15:08:01

- 抽出公共反代参数 `proxy-params.inc`：HTTP/1.1 keepalive + WebSocket 升级、超时与缓冲、隐藏后端指纹、拒绝客户端伪造的 `X-Forwarded-*` / `Proxy`
- 新增 `000-upstreams.conf` 上游连接池（`conf.d` 走 `host.docker.internal`，`conf.d.alias` 走 compose service name）；PHP 上游仅写在 `conf.d.php` 以免非 full 栈启动失败
- 未知 Host 的 default server 改为直接 `444`；`php.conf` 补上 `anti-scan-php.inc`
- `nginx.conf` 开启 `tcp_nopush`/`tcp_nodelay`、`gzip_proxied`，并为 JSON 等反代响应启用压缩
- README 补充上游连接池与公共反代参数说明

commit message: `perf: 优化 nginx 反向代理效率与转发安全`

## 2026-08-10 15:56:15

- 修复 `anti-scan-php.inc`：`if` 正则中的 `$` 被当成变量导致 `invalid condition`
- 改为 `map` 拆分 `$is_scanner_uri` / `$is_php_probe`，PHP 站点仅跳过 `.php` 拦截

commit message: `fix: 修复 anti-scan-php 因 $ 变量解析导致的 nginx 配置错误`

## 2026-08-10 15:51:04

- 防扫描 URI 规则补充：`.php` / `.asp(x)` / `.ashx` / `wp-*` / `xmlrpc` / `.git` / `.rar|.zip|.gz`
- PHP 站点改用 `anti-scan-php.inc`，避免拦截合法 `.php` 业务请求
- 同步更新 fail2ban `nginx-scanner` 过滤规则

commit message: `feat: 扩展 nginx 漏洞扫描路径拦截规则`

## 2026-08-10 14:27:49

- 将其余 compose（`yml` / `mongo` / `postgres` / `full.mongo`）同步接入 fail2ban 与 nginx 日志挂载
- `nginx/conf.d` 同步防扫描配置，保证仅 Nginx 栈同样生效

commit message: `feat: 各 compose 统一接入 nginx 防扫描防火墙`

## 2026-08-10 13:44:13

- 为 `full.postgres` 的 nginx 增加防恶意扫描防护：URI/UA 拦截、限流、IP 黑名单
- 新增 `fail2ban` 服务（与 nginx 共享网络命名空间），按访问日志自动 iptables 封禁
- 相关配置：`nginx/conf.d.alias/000-security-*.conf`、`anti-scan.inc`、`fail2ban/`

commit message: `feat: 为 nginx 增加防恶意扫描防火墙`

## 2026-08-04 11:18:31

- 重构 `dc.sh` 交互选择：改用全局变量 `PICKED_*` 返回结果，不再用 `$(...)` / `eval`
- 消除 `syntax error near unexpected token fi` 隐患，并保证选 `q` 能真正退出

commit message: `fix: 重构 dc.sh 交互菜单避免子 shell 语法问题`

## 2026-08-04 11:12:15

- 修复 `./dc.sh` 交互菜单不显示：菜单改输出到 stderr，避免被 `$(...)` 吞掉
- 修复交互选 `q` 无法真正退出：`$(...)` 内 `exit` 只结束子 shell，改为哨兵 `__QUIT__` 由调用方退出

commit message: `fix: 修复 dc.sh 交互菜单显示与退出`

## 2026-08-04 11:03:33

- 重命名 `docker-compose.prod.yml` → `docker-compose.mongo.yml`
- 重命名 `docker-compose.full.yml` → `docker-compose.full.mongo.yml`
- 同步更新 `dc.sh` stack 别名（`mongo` / `full.mongo`，兼容旧别名 `prod` / `full`）与 README

commit message: `refactor: Mongo 栈 compose 文件按数据库命名`

## 2026-08-04 10:57:20

- 按服务功能统一各 compose 的 `restart` 策略：数据库 / API / SSR / PHP / Nginx 均使用 `unless-stopped`
- `docker-compose.yml` 中 nginx 由 `always` 调整为 `unless-stopped`，与其余栈一致
- `docker-compose.postgres.yml` 已齐全，无需改动

commit message: `chore: 统一各服务 restart 策略为 unless-stopped`

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

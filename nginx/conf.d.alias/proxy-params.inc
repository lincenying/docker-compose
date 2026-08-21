# 公共反向代理参数（在 location 内 include）
# include /etc/nginx/conf.d/proxy-params.inc;
#
# 效率：HTTP/1.1 + 空 Connection 复用上游 keepalive；有 Upgrade 时自动切 WebSocket
# 安全：不信任客户端 X-Forwarded-*；去掉 Proxy 头（httpoxy）；隐藏后端指纹

proxy_http_version 1.1;
proxy_redirect off;
proxy_socket_keepalive on;

proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $remote_addr;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_set_header Proxy "";

proxy_connect_timeout 5s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;

proxy_buffer_size 16k;
proxy_buffers 8 16k;
proxy_busy_buffers_size 32k;
proxy_max_temp_file_size 64m;

proxy_hide_header X-Powered-By;
proxy_hide_header Server;
proxy_hide_header X-AspNet-Version;
proxy_hide_header X-AspNetMvc-Version;

add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header X-XSS-Protection "0" always;

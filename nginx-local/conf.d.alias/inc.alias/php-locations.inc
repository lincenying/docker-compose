# 入口 Nginx 直接把 PHP 交给 app_php:9000。
# 站点文件来自与 app_php 共用的卷，路径必须与 PHP 容器内一致。
root /home/web/app-php;
index index.php index.html index.htm;

resolver 127.0.0.11 valid=10s ipv6=off;

location ~ /\. {
    deny all;
}

location ~* ^/(inc|logs|cache|vendor|twig)/ {
    deny all;
}

location ~* ^/upload/.+\.php$ {
    deny all;
}

location ~* \.(?:css|js|jpg|jpeg|gif|png|svg|ico|webp|woff2?)$ {
    expires 7d;
    access_log off;
    try_files $uri =404;
}

location / {
    try_files $uri $uri/ /index.php?q=$uri&$args;
}

location ~ \.php$ {
    try_files $uri =404;
    set $php_upstream app_php:9000;
    fastcgi_pass $php_upstream;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_hide_header X-Powered-By;
    fastcgi_connect_timeout 5s;
    fastcgi_read_timeout 60s;
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;
}

rewrite ^/api/ajax\/([a-zA-Z_\-]+)$ /ajax.php?action=$1 last;
rewrite ^/api/fetch\/([a-zA-Z_\-\/]+)$ /ajax.php?action=$1 last;

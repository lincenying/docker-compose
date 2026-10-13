# PHP 站点专用：不拦截 .php（否则业务不可用），其余扫描规则与限流仍生效
# include /etc/nginx/conf.d/anti-scan-php.inc;

if ($is_scanner_uri) {
    return 444;
}

if ($is_bad_bot) {
    return 444;
}

limit_req zone=anti_scan burst=30 nodelay;
limit_req_status 429;

limit_conn perip_conn 40;
limit_conn_status 429;

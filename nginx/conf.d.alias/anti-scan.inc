# 在 server 块内 include：拦截扫描并限流
# include /etc/nginx/conf.d/anti-scan.inc;

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

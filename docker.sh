#!/usr/bin/env bash

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-bun-mongodb:1.26.0728
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-bun-mongodb:1.26.0728 lincenying/api-bun-mongodb:1.26.0728
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-bun-mongodb:1.26.0728

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-bun-postgre:1.26.0804
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-bun-postgre:1.26.0804 lincenying/api-bun-postgre:1.26.0804
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-bun-postgre:1.26.0804

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-express:1.26.0803
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-express:1.26.0803 lincenying/api-express:1.26.0803
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/api-express:1.26.0803

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-nuxt:1.26.0727
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-nuxt:1.26.0727 lincenying/app-nuxt:1.26.0727
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-nuxt:1.26.0727

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-php:1.26.0727
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-php:1.26.0727 lincenying/app-php:1.26.0727
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-php:1.26.0727

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-vue3-ssr:1.26.0731
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-vue3-ssr:1.26.0731 lincenying/app-vue3-ssr:1.26.0731
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/app-vue3-ssr:1.26.0731

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/nginx-php:1.26.0727
docker tag swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/nginx-php:1.26.0727 lincenying/nginx-php:1.26.0727
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/lincenying/nginx-php:1.26.0727

docker pull swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/crazymax/fail2ban:1.1.0
docker tag  swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/crazymax/fail2ban:1.1.0 crazymax/fail2ban:1.1.0
docker rmi swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/crazymax/fail2ban:1.1.0

# docker-compose

```bash
# 生成镜像及启动容器
# 后端服务器一起启动
docker-compose -f docker-compose.prod.yml up -d

# 只启动nginx服务
docker-compose -f docker-compose.yml up -d
```

## 开启php项目

### 复制项目
将php项目代码复制到`./web/demo-php`目录下

### 相关配置
修改`docker-compose.full.yml`中的`mysql_db.volumes`配置, 将宿主机数据库路径映射到容器中, 可实现数据持久化

```yaml
volumes:
  - /Users/lincenying/web/mysqldb:/var/lib/mysql
```

修改`docker-compose.yml`中的相关配置
```yaml
# 给php用的
DB_PORT: 3306
DB_DATABASE: cyxiaowu
DB_USERNAME: user
DB_PASSWORD: password

# 给mysql用的, 上下得一一对应
MYSQL_ROOT_PASSWORD: rootpassword
MYSQL_DATABASE: cyxiaowu
MYSQL_USER: user
MYSQL_PASSWORD: password

# php应用映射到宿主机的端口
webserver:
  ports:
    - '8084:80'
```

根据情况自行修改`nginx/conf.d/php.conf`或者`nginx/conf.d.alias/php.conf`配置, 如果域名绑定, 端口号等
nginx配置文件根据`docker-compose.*.yaml`文件中的
```yaml
nginx:
  volumes:
    - ./nginx/conf.d.alias:/etc/nginx/conf.d
```
来决定是使用`conf.d`还是`conf.d.alias`文件夹里的配置

如果宿主机有数据库, 或者使用外部的数据库, 可以删除`docker-compose.yml`中`mysql_db`容器, 并修改`app/inc/settings.ini.php`中的数据库配置

```bash
# 生成镜像及启动容器
# 后端服务器一起启动
docker-compose -f docker-compose.full.yml up -d

# 进入mysql_db容器
docker exec -it mysql /bin/bash
# 恢复mysql数据库
mysql -uuser -p cyxiaowu < /home/mysql/mysql.sql

# 进入php-app容器
docker exec -it php-app /bin/bash
# 安装composer依赖
cd /home/web/php-template
composer install --no-dev --no-scripts --no-autoloader
composer dump-autoload --optimize

```

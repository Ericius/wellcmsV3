# wellcmsV3 for Coolify — PHP 8.3-FPM + Nginx 單容器
# 用法：放到你 fork 的 wellcmsV3 倉庫根目錄，Coolify 選 Dockerfile 構建
FROM php:8.3-fpm

# 系統依賴 + PHP 擴展
# 官方需求：pdo、mbstring、gd、fileinfo、openssl；pdo_pgsql 給 PostgreSQL 用
RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx \
        libpq-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libzip-dev \
        libonig-dev \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" pdo pdo_pgsql pdo_mysql mbstring gd exif fileinfo zip opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 上傳限制放寬（CMS 上傳附件用）
RUN printf "upload_max_filesize=50M\npost_max_size=55M\nmemory_limit=256M\n" \
    > /usr/local/etc/php/conf.d/wellcms.ini

WORKDIR /var/www/html
COPY . /var/www/html

# Nginx 設定（按容器路徑改寫的官方 nginx.conf.example）
COPY nginx.conf /etc/nginx/sites-enabled/default

# 可寫目錄：安裝精靈要寫 config/、install/install.lock，上傳寫 storage/
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/config /var/www/html/install \
    && chmod -R 775 /var/www/html/storage /var/www/html/config /var/www/html/install

EXPOSE 80

# nginx 背景啟動，php-fpm 前台保活容器
CMD ["sh", "-c", "nginx && exec php-fpm -F"]

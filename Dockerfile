FROM dmstr/php-yii2:7.1-fpm-3.2-alpine-nginx

RUN apk add --update $PHPIZE_DEPS \
 && pecl install mailparse \
 && docker-php-ext-enable mailparse \
 && apk del $PHPIZE_DEPS

# System files
COPY ./image-files /
RUN chmod u+x /usr/local/bin/*

# Application packages
WORKDIR /app
COPY composer.* /app/
RUN composer install --prefer-dist --optimize-autoloader && \
    composer clear-cache

# Application source-code
COPY yii /app/
COPY ./web /app/web/
COPY ./src /app/src/

# Permissions; run yii commands as webserver user
ENV PHP_USER_ID=82
RUN mkdir -p runtime web/assets web/bundles /mnt/storage && \
    chmod -R 775 runtime web/assets web/bundles /mnt/storage && \
    chmod -R ugo+r /root/.composer/vendor && \
    chown -R www-data:www-data runtime web/assets web/bundles /root/.composer/vendor /mnt/storage && \
    APP_NO_CACHE=1 APP_LANGUAGES=en yii asset/compress src/config/assets.php web/bundles/config.php

# Install crontab from application config
RUN crontab src/config/crontab

VOLUME /mnt/storage
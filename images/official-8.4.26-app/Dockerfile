FROM composer:2 AS deps
WORKDIR /app
COPY composer.json ./
RUN composer install --no-dev --no-interaction --no-progress

FROM php:8.4.26-cli
WORKDIR /app
COPY --from=deps /app/composer.json /app/composer.lock ./
COPY --from=deps /app/vendor ./vendor
COPY index.php ./
CMD ["php", "index.php"]

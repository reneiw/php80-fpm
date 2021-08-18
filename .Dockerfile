#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#

FROM php:8.0-fpm

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
            apt-utils \
            cron \
            curl \
            libmemcached-dev \
            libz-dev \
            libpq-dev \
            libjpeg-dev \
            libpng-dev \
            libfreetype6-dev \
            libssl-dev \
            libmcrypt-dev \
            libonig-dev \
            supervisor

RUN docker-php-ext-install bcmath exif mysqli mbstring opcache pcntl pdo pdo_mysql tokenizer xml
    # Install the PHP gd library
RUN docker-php-ext-configure gd --prefix=/usr --with-jpeg --with-freetype && \
    docker-php-ext-install gd

RUN apt-get update -yqq && \
    pecl channel-update pecl.php.net && \
    apt-get install -yqq \
      apt-utils \
      libzip-dev zip unzip && \
      docker-php-ext-configure zip && \
      docker-php-ext-install zip && \
      php -m | grep -q 'zip' && \
      apt-get -y install libxslt-dev && \
      docker-php-ext-install xsl

RUN pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

RUN rm -rf /var/lib/apt/lists/*

RUN php -v | head -n 1

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

COPY ./laravel.ini /usr/local/etc/php/conf.d
COPY ./xlaravel.pool.conf /usr/local/etc/php-fpm.d/

USER root

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

# Configure non-root user.
ARG PUID=5000
ENV PUID ${PUID}
ARG PGID=5000
ENV PGID ${PGID}

RUN groupadd -g ${PGID} www && \
    useradd -o -u ${PUID} -g www www

ARG LOCALE=POSIX
ENV LC_ALL ${LOCALE}
WORKDIR /var/www
CMD ["php-fpm"]

EXPOSE 9000
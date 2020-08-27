FROM php:latest
LABEL maintainer="Maxime Flasquin contact@mflasquin.fr"

# =========================================
# RUN update
# =========================================
RUN apt-get update

# =========================================
# Install dependencies
# =========================================
RUN apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxslt1-dev \
    libzip-dev \
    pdftk \
    sudo \
    libmagickwand-dev \
    libmagickcore-dev \
    apt-transport-https

# =========================================
# Install tools
# =========================================
RUN apt-get install -y \
    vim \
    htop \
    openssl

# =========================================
# Configure the GD library
# =========================================
RUN docker-php-ext-configure \
    gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

# =========================================
# Install php required extensions
# =========================================
RUN docker-php-ext-install \
  dom \
  gd \
  intl \
  mbstring \
  pdo_mysql \
  xsl \
  zip \
  soap \
  bcmath \
  mysqli \
  sockets \
  exif

# =========================================
# Install apcu
# =========================================
RUN pecl install -f apcu

# =========================================
# Install imagick
# =========================================
RUN pecl install -f imagick

# =========================================
# Set ENV variables
# =========================================
ENV PHP_MEMORY_LIMIT 2G
ENV DEBUG false
ENV UPLOAD_MAX_FILESIZE 64M
ENV PROJECT_ROOT /var/www/htdocs

# =========================================
# Create mflasquin user
# =========================================
RUN openssl rand -base64 32 > ./.pass \
	&& useradd -ms /bin/bash --password='$(cat ./.pass)' mflasquin \
	&& echo "$(cat ./.pass)\n$(cat ./.pass)\n" | passwd mflasquin \
	&& mv ./.pass /home/mflasquin/ \
	&& chown -Rf mflasquin:mflasquin /home/mflasquin
ADD ./bashrc.mflasquin /home/mflasquin/.bashrc

# =========================================
# PHP Configuration
# =========================================
ADD etc/php-xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug-settings.ini
ADD etc/php-fpm.conf /usr/local/etc/
ADD etc/php-fpm.ini /usr/local/etc/php/conf.d/zz-custom.ini

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# =========================================
# Set entrypoint
# =========================================
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN ["chmod", "+x", "/docker-entrypoint.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]

WORKDIR $PROJECT_ROOT

CMD ["php-fpm", "-F"]
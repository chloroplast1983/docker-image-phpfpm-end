#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:jessie

# persistent / runtime deps
ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev \
		file \
		g++ \
		gcc \
		libc-dev \
		libpcre3-dev \
		make \
		pkg-config \
		re2c
RUN apt-get update && apt-get install -y \
		$PHPIZE_DEPS \
		ca-certificates \
		curl \
		libedit2 \
		libsqlite3-0 \
		libxml2 \
		xz-utils \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d

##<autogenerated>##
ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data
##</autogenerated>##

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS A917B1ECDA84AEC2B568FED6F50ABC807BD5DCD0 528995BFEDFBA7191D46839EF9BA0ADA31CBD89E

ENV PHP_VERSION 7.1.9
ENV PHP_URL="https://secure.php.net/get/php-7.1.9.tar.xz/from/this/mirror" PHP_ASC_URL="https://secure.php.net/get/php-7.1.9.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="ec9ca348dd51f19a84dc5d33acfff1fba1f977300604bdac08ed46ae2c281e8c" PHP_MD5=""

RUN set -xe; \
	\
	fetchDeps=' \
		wget \
	'; \
	if ! command -v gpg > /dev/null; then \
		fetchDeps="$fetchDeps \
			dirmngr \
			gnupg2 \
		"; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	wget -O php.tar.xz "$PHP_URL"; \
	\
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi; \
	if [ -n "$PHP_MD5" ]; then \
		echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
	fi; \
	\
	if [ -n "$PHP_ASC_URL" ]; then \
		wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps

COPY docker-php-source /usr/local/bin/

RUN set -xe \
	&& buildDeps=" \
		$PHP_EXTRA_BUILD_DEPS \
		libcurl4-openssl-dev \
		libedit-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		zlib1g-dev \
	" \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	\
	&& export CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
# https://bugs.php.net/bug.php?id=74125
	&& if [ ! -d /usr/include/curl ]; then \
		ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
	fi \
	&& ./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
		--disable-cgi \
		\
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
		\
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
                --disable-session \
                --enable-zip \
                --enable-bcmath \
                --with-pdo-mysql=mysqlnd \
                --enable-pcntl \
                --enable-sysvmsg \
                --enable-sysvsem \
                --enable-sysvshm \
                --enable-sockets \
		\
# bundled pcre is too old for s390x (which isn't exactly a good sign)
# /usr/src/php/ext/pcre/pcrelib/pcre_jit_compile.c:65:2: error: #error Unsupported architecture
		--with-pcre-regex=/usr \
		--with-libdir="lib/$debMultiarch" \
		\
		$PHP_EXTRA_CONFIGURE_ARGS \
	&& make -j "$(nproc)" \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	&& cd / \
	&& docker-php-source delete \
	\
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps \
	\
# https://github.com/docker-library/php/issues/443
	&& pecl update-channels \
	&& rm -rf /tmp/pear ~/.pearrc

COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/

ENTRYPOINT ["docker-php-entrypoint"]
##<autogenerated>##
WORKDIR /var/www/html

RUN set -ex \
	&& cd /usr/local/etc \
	&& if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi \
	&& { \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; \
		echo '[www]'; \
		echo '; if we send this to /proc/self/fd/1, it never appears'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
	} | tee php-fpm.d/docker.conf \
	&& { \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = [::]:9000'; \
	} | tee php-fpm.d/zz-docker.conf \
    # install extensions
    && apt-get update && apt-get install -y libmemcached-dev zlib1g-dev git libssl-dev --no-install-recommends \ 
        && rm -r /var/lib/apt/lists/* \
        && pecl download memcached-3.0.3 \
        && mkdir -p memcached \
        && tar -xf memcached-3.0.3.tgz  -C memcached --strip-components=1 \
        && rm memcached-3.0.3.tgz \
        && ( \
                cd memcached \
                && phpize \
                && ./configure --disable-memcached-session \
                && make -j$(nproc) \
                && make install \
        ) \
        && rm -r memcached \
        && pecl download redis-3.1.3 \
        && mkdir -p redis \
        && tar -xf redis-3.1.3.tgz -C redis --strip-components=1 \
        && rm redis-3.1.3.tgz \
        && ( \
                cd redis \
                && phpize \
                && ./configure --disable-redis-session \
                && make -j$(nproc) \
                && make install \
        ) \
        && rm -r redis \
        && pecl install mongodb-1.2.10 \
        && docker-php-ext-enable memcached redis mongodb 

COPY marmot.so /usr/local/lib/php/extensions/no-debug-non-zts-20160303/
COPY confd composer /usr/local/bin/
# modify ini, conf
RUN echo "memcached.default_consistent_hash = on" >> /usr/local/etc/php/conf.d/docker-php-ext-memcached.ini \
    && echo "extension=marmot.so" > /usr/local/etc/php/conf.d/marmot.ini \
    && set -ex \
    && { \
        echo 'zend_extension=opcache.so'; \
        echo 'opcache.enable=1'; \
        echo 'opcache.enable_cli=1'; \
        echo 'opcache.huge_code_pages=1'; \
    } | tee /usr/local/etc/php/conf.d/opcache.ini \
    && { \
         echo 'post_max_size = 5M'; \
         echo "date.timezone = 'PRC'"; \
         echo "memory_limit = '256M'"; \
         echo 'open_basedir = /var/www/html:/tmp:/usr/local/bin'; \
         echo 'upload_tmp_dir = /var/www/html/cache/tmp'; \
         echo 'file_uploads = off'; \
         echo 'display_errors = off'; \
         echo 'error_reporting = E_ALL;' \
         echo 'log_errors = on'; \
         echo 'expose_php = off'; \
    } | tee /usr/local/etc/php/conf.d/core.ini \
    && sed -i -e '/pm.max_children/s/5/100/' \
           -e '/pm.start_servers/s/2/40/' \
           -e '/pm.min_spare_servers/s/1/20/' \
           -e '/pm.max_spare_servers/s/3/60/' \
           -e 's/;slowlog = log\/$pool.log.slow/slowlog = \/proc\/self\/fd\/2/1' \
           -e 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 5s/1' \
           /usr/local/etc/php-fpm.d/www.conf 

ENV COMPOSER_CACHE_DIR /var/www/html/cache/composer
ENV COMPOSER_HOME /var/www/html/

EXPOSE 9000
CMD ["php-fpm"]
##</autogenerated>##

FROM registry.cn-hangzhou.aliyuncs.com/phpfpm/phpfpm-end-base:1.6

RUN pecl install xdebug-2.9.8 \
    && docker-php-ext-enable xdebug \
    && set -ex \
    && { \
        echo 'zend_extension=opcache.so'; \
        echo 'opcache.enable=0'; \
        echo 'opcache.enable_cli=0'; \
        echo 'opcache.opcache.memory_consumption=256'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.opcache.max_accelerated_files=11000'; \
        echo 'opcache.huge_code_pages=0'; \
        echo 'opcache.validate_timestamps=0'; \
        echo 'opcache.revalidate_freq=0'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.fast_shutdown=1'; \
    } | tee /usr/local/etc/php/conf.d/opcache.ini \
    && { \
         echo 'post_max_size = 5M'; \
         echo "date.timezone = 'PRC'"; \
         echo "memory_limit = '256M'"; \
         echo 'upload_tmp_dir = /var/www/html/cache/tmp'; \
         echo 'file_uploads = off'; \
         echo 'display_errors = off'; \
         echo 'html_errors = off'; \
         echo 'error_reporting = E_ALL'; \
         echo 'log_errors = on'; \
         echo 'expose_php = off'; \
         echo 'disable_functions=chmod, \
                                 chgrp,chown, \
                                 chroot, \
                                 exec,system,shell_exec,popen, \
                                 dl, \
                                 disk_total_space,disk_free_space,diskfreespace,phpinfo, \
                                 '; \
    } | tee /usr/local/etc/php/conf.d/core.ini \
    && jsonlog='{"request_id":"%{REQUEST_ID}e","remote_ip":"%R","server_time":"%{%Y-%m-%dT%H:%M:%S%z}t","request_method":"%m","request_uri":"%r%Q%q","status":"%s","script_filename":"%f","server_request_millsecond":"%{mili}d","peak_memory_kb":"%{kilo}M","total_request_cpu":"%C%%"}' \
    && sed -i -e '/pm.max_children/s/5/100/' \
           -e '/pm.start_servers/s/2/40/' \
           -e '/pm.min_spare_servers/s/1/20/' \
           -e '/pm.max_spare_servers/s/3/60/' \
           -e 's/;slowlog = log\/$pool.log.slow/slowlog = \/proc\/self\/fd\/2/1' \
           -e 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 5s/1' \
           -e "s/^;access.format = .*$/access.format = '${jsonlog}'/" \
           /usr/local/etc/php-fpm.d/www.conf \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

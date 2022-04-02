#!/bin/bash

NGINX_VERSION='1.21.6'
PHP_VERSION='8.1.4'
MYSQL_VERSION='8.0.28'
REDIS_VERSION='6.2.6'

function check() {
  if [ $1 -eq 0 ]; then
    echo 'successfully'
  else
    echo 'failed'
    tail -n 10 /tmp/install.log
    exit 1
  fi
}

function environment() {
  echo 'Compiling environment ...'
  sed -i 's|deb.debian.org|mirrors.tuna.tsinghua.edu.cn|' /etc/apt/sources.list
  sed -i 's|security.debian.org|mirrors.tuna.tsinghua.edu.cn|' /etc/apt/sources.list
  echo -n 'apt update... '
  apt update >>/tmp/install.log 2>&1
  check $?
  echo -n 'apt install compiling environment...'
  apt install -y --no-install-recommends xz-utils wget ca-certificates g++ gcc make pkg-config >>/tmp/install.log 2>&1
  check $?
  if [ ! -f /etc/vim/vimrc.local ]; then
    {
      echo 'source $VIMRUNTIME/defaults.vim'
      echo 'let skip_defaults_vim = 1'
      echo 'if has('mouse')'
      echo '  set mouse=r'
      echo 'endif'
    } >/etc/vim/vimrc.local
  fi
  echo 'Compiling environment finished'
}

function nginx() {
  if [ -d /usr/local/nginx ]; then echo 'Nginx compiled' && /usr/local/nginx/sbin/nginx -version && exit 1; fi

  echo 'Nginx compiling ...'
  echo -n 'apt install Nginx dependency ...'
  apt install -y --no-install-recommends libpcre3-dev openssl zlib1g-dev libxml2-dev libxslt-dev libgd-dev >>/tmp/install.log 2>&1
  check $?

  if ! id www >/dev/null 2>&1; then
    echo -n 'Nginx groupadd www ...'
    groupadd www && useradd www -g www -s /sbin/nologin
    check $?
  fi

  if [ -f ./nginx-$NGINX_VERSION.tar.gz ]; then
    echo 'Nginx downloaded'
  else
    echo -n 'Nginx downloading ...'
    wget -q --no-clobber -O ./nginx-$NGINX_VERSION.tar.gz http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
    if [ $? -eq 0 ]; then echo 'successfully'; else echo 'failed' && exit 1; fi
  fi

  echo -n 'Nginx uncompressing ...'
  tar zxf nginx-$NGINX_VERSION.tar.gz
  check $?

  cd nginx-$NGINX_VERSION || (echo "nginx-$NGINX_VERSION Directory does not exist" && exit 1)
  echo -n 'Nginx configure ...'
  ./configure \
    --user=www \
    --group=www \
    --prefix=/usr/local/nginx \
    --conf-path=/Web/Nginx/nginx.conf \
    --error-log-path=/Web/Logs/nginx_error.log \
    --http-log-path=/Web/Logs/nginx_access.log \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module \
    --with-http_image_filter_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-stream \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_ssl_preread_module >>/tmp/install.log 2>&1
  check $?
  echo -n 'Nginx make ...'
  make --silent --jobs $(nproc) >>/tmp/install.log 2>&1
  check $?
  echo -n 'Nginx make install ...'
  make install clean >>/tmp/install.log 2>&1
  check $?

  cd ..
  rm -rf nginx-$NGINX_VERSION.tar.gz
  rm -rf nginx-$NGINX_VERSION

  /usr/local/nginx/sbin/nginx -version
  path '/usr/local/nginx/sbin'
  echo "Nginx compile finished"
}

function php() {
  if [ -d /usr/local/php ]; then echo 'PHP compiled' && /usr/local/php/bin/php --version && exit 1; fi

  echo "PHP $PHP_VERSION compiling ..."
  echo -n 'apt install PHP dependency ...'
  apt install -y --no-install-recommends file systemtap-sdt-dev libcurl4-openssl-dev libxml2-dev libpng-dev libsqlite3-dev libbz2-dev libssl-dev libgd-dev libgmp-dev libonig-dev unixodbc-dev libxslt1-dev libzip-dev >>/tmp/install.log 2>&1
  check $?

  if ! id www >/dev/null 2>&1; then
    echo -n 'PHP groupadd www ...'
    groupadd www && useradd www -g www -s /sbin/nologin
    check $?
  fi

  if [ -f ./php-$PHP_VERSION.tar.xz ]; then
    echo 'PHP downloaded'
  else
    echo -n 'PHP downloading ...'
    wget -q --no-clobber -O ./php-$PHP_VERSION.tar.xz https://www.php.net/distributions/php-$PHP_VERSION.tar.xz
    if [ $? -eq 0 ]; then echo 'successfully'; else echo 'failed' && exit 1; fi
  fi

  echo -n 'PHP uncompressing ...'
  tar xf php-$PHP_VERSION.tar.xz
  check $?

  cd php-$PHP_VERSION || (echo "php-$PHP_VERSION Directory does not exist" && exit 1)
  echo -n 'PHP configure ...'
  ./configure --silent \
    --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-mysqli \
    --with-pdo-mysql \
    --with-pdo-odbc=unixODBC,/usr \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-curl \
    --with-pear \
    --with-external-gd \
    --with-webp \
    --with-jpeg \
    --with-xpm \
    --with-freetype \
    --with-iconv \
    --with-mhash \
    --with-openssl \
    --with-xsl \
    --with-bz2 \
    --with-gettext \
    --with-zlib \
    --with-zip \
    --with-gmp \
    --enable-fpm \
    --enable-libgcc \
    --enable-bcmath \
    --enable-calendar \
    --enable-dtrace \
    --enable-dba \
    --enable-exif \
    --enable-ftp \
    --enable-gd \
    --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-zts >>/tmp/install.log 2>&1
  check $?
  echo -n 'PHP make ...'
  make --silent --jobs $(nproc) >>/tmp/install.log 2>&1
  check $?
  echo -n 'PHP make install ...'
  make install clean >>/tmp/install.log 2>&1
  check $?

  echo -n 'PHP config ...'
  cp php.ini-production /usr/local/php/etc/php.ini &&
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf &&
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf &&
    sed -i 's|^;error_log = php_errors.log$|error_log = /Web/Logs/php_error.log|' /usr/local/php/etc/php.ini &&
    sed -i 's|^;error_log = log/php-fpm.log$|error_log = /Web/Logs/php_fpm.log|' /usr/local/php/etc/php-fpm.conf &&
    {
      echo ''
      echo ''
      echo ''
    } >>/usr/local/php/etc/php.ini
  check $?

  cd ..
  rm -rf php-$PHP_VERSION.tar.xz
  rm -rf php-$PHP_VERSION

  /usr/local/php/bin/php --version
  path '/usr/local/php/bin:/usr/local/php/sbin'
  echo "PHP $PHP_VERSION compile finished"
}

function mysql() {
  if [ -d /usr/local/mysql ]; then echo 'MySQL compiled' && /usr/local/mysql/bin/mysql --version && exit 1; fi

  echo 'MySQL compiling ...'
  echo -n 'apt install MySQL dependency ...'
  apt install -y --no-install-recommends libaio1 libnuma1 libncurses5 >>/tmp/install.log 2>&1
  check $?

  if ! id mysql >/dev/null 2>&1; then
    echo -n 'MySQL groupadd mysql ...'
    groupadd mysql && useradd mysql -g mysql -M -s /sbin/nologin
    check $?
  fi

  if [ -f ./mysql-$MYSQL_VERSION-linux-glibc2.17-x86_64-minimal.tar.xz ]; then
    echo 'MySQL downloaded'
  else
    echo -n 'MySQL downloading ...'
    wget -q --no-clobber -O ./mysql-$MYSQL_VERSION-linux-glibc2.17-x86_64-minimal.tar.xz https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-$MYSQL_VERSION-linux-glibc2.17-x86_64-minimal.tar.xz
    if [ $? -eq 0 ]; then echo 'successfully'; else echo 'failed' && exit 1; fi
  fi
  echo -n 'MySQL uncompressing ...'
  tar xf mysql-$MYSQL_VERSION-linux-glibc2.17-x86_64-minimal.tar.xz
  check $?
  echo -n 'MySQL config ...'
  mv mysql-$MYSQL_VERSION-linux-glibc2.17-x86_64-minimal /usr/local/mysql &&
    mkdir /usr/local/mysql/etc &&
    {
      echo '[mysqld]'
      echo 'datadir = /Web/MySQL'
      echo 'log_error = /Web/Logs/mysq_error.log'
      echo 'long_query_time = 1'
      echo 'slow_query_log = 1'
      echo 'slow_query_log_file = /Web/Logs/mysq_slow.log'
      echo 'default_authentication_plugin = mysql_native_password'
      echo 'binlog_cache_size = 64M'
      echo 'max_connections = 1024'
      echo '[client]'
      echo 'protocol=tcp'
    } >/usr/local/mysql/etc/my.cnf
  check $?

  rm -rf mysql-$MYSQL_VERSION-linux-glibc2.17-x86_64-minimal.tar.xz

  /usr/local/mysql/bin/mysql --version
  path /usr/local/mysql/bin
  echo "MySQL compile finished"
}

function redis() {
  if [ -d /usr/local/redis ]; then echo 'Redis compiled' && /usr/local/redis/bin/redis-server --version && exit 1; fi

  echo 'Reids compiling ...'

  if ! id redis >/dev/null 2>&1; then
    echo -n 'Reids groupadd redis ...'
    groupadd redis && useradd redis -g redis -M -s /sbin/nologin
    check $?
  fi

  if [ -f ./redis-$REDIS_VERSION.tar.gz ]; then
    echo 'Redis downloaded'
  else
    echo -n 'Redis downloading ...'
    wget -q --no-clobber -O ./redis-$REDIS_VERSION.tar.gz https://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz
    if [ $? -eq 0 ]; then echo 'successfully'; else echo 'failed' && exit 1; fi
  fi

  echo -n 'Redis uncompressing ...'
  tar zxf redis-$REDIS_VERSION.tar.gz
  check $?

  cd redis-$REDIS_VERSION || (echo "redis-$REDIS_VERSION Directory does not exist" && exit 1)
  echo -n 'Redis make install ...'
  make PREFIX=/usr/local/redis install >>/tmp/install.log 2>&1
  check $?

  echo -n 'Redis config ...'
  mkdir -p /Web/Redis &&
    cp redis.conf /Web/Redis &&
    sed -i 's|^logfile ""$|logfile "/Web/Logs/redis.log"|' /Web/Redis/redis.conf &&
    sed -i 's|^# save 3600 1$|save 3600 1|' /Web/Redis/redis.conf &&
    sed -i 's|^# save 300 100$|save 300 100|' /Web/Redis/redis.conf &&
    sed -i 's|^# save 60 10000$|save 60 10000|' /Web/Redis/redis.conf &&
    sed -i 's|^dir ./$|dir "/Web/Redis"|' /Web/Redis/redis.conf &&
    chown -R redis:redis /Web/Redis
  check $?

  cd ..
  rm -rf redis-$REDIS_VERSION.tar.gz
  rm -rf redis-$REDIS_VERSION

  /usr/local/redis/bin/redis-server --version
  path /usr/local/redis/bin
  echo "Reids compile finished"
}

function pecl() {
  for i in "$@"; do
    echo -n "pecl install $i ..."
    echo | /usr/local/php/bin/pecl install $i >>/tmp/install.log 2>&1
    check $?
    echo "extension=$i.so" >>/usr/local/php/etc/php.ini
  done
}

function path() {
  if grep 'PATH' ~/.bashrc >/dev/null; then
    if grep $1 ~/.bashrc >/dev/null; then
      echo "already exist Add \$PATH:$1 in ~/.bashrc"
    else
      sed -i "s|^PATH.*$|&:$1|" ~/.bashrc
      echo "\$PATH:$1 to ~/.bashrc"
    fi
  else
    {
      echo ''
      echo ''
      echo ''
      echo 'PATH=$PATH'
    } >>~/.bashrc
    echo 'Add default PATH to ~/.bashrc'
  fi
}
echo '' >/tmp/install.log
if [ ! -f /etc/debian_version ]; then echo 'Only support Debian' && exit 1; fi
echo "
  1. Set compile environment on Debian $(cat /etc/debian_version)
  2. Compile Nginx $NGINX_VERSION
  3. Compile PHP $PHP_VERSION
  4. Compile MySQL $MYSQL_VERSION
  5. Compile Redis $REDIS_VERSION
  6. Pecl install PHP Extensions
"
echo -n 'Please enter the program number you want to compile: '
read -r number
case $number in
1)
  environment
  ;;
2)
  nginx
  ;;
3)
  php
  ;;
4)
  mysql
  ;;
5)
  redis
  ;;
6)
  echo -n 'Please enter the name extensions to pecl: '
  read -r extensions
  pecl $extensions
  ;;
*)
  echo '暂时无法处理您的选择'
  ;;
esac
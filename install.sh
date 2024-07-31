#!/bin/bash

ztds_version='ztds_v.0.8.4'

clear

read -p 'Enter domain name (e.g. site.ru) and press [ENTER]: ' domain </dev/tty


# Установка необходимых пакетов
apt update
apt install -y ufw p7zip-full nginx php-fpm php-cli php-gd php-ldap php-odbc php-pdo php-memcache php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap unzip

# Установка UFW и настройка правил
ufw allow 'Nginx Full'
ufw allow 'OpenSSH'
ufw --force enable

# Конфигурация nginx
/bin/cat <<EOM >/etc/nginx/sites-available/$domain
server {
    listen 80;
    server_name $domain www.$domain;

    root /var/www/html/$domain;

    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }

    location ~* \.(jpg|jpeg|gif|png|js|css|txt|zip|ico|gz|csv)\$ {
        access_log off;
        expires max;
    }

    location ~* /(database|ini|keys|lib|log)/.*\$ {
        return 403;
    }

    location ~* \.(htaccess|ini|txt|db)\$ {
        return 403;
    }
}

EOM

ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/

# Перезапуск сервисов
systemctl restart nginx
systemctl restart php7.4-fpm

# Создание необходимых директорий
mkdir -p /var/lib/php/session
mkdir -p /var/www/html/$domain
chmod 777 /var/lib/php/session
chmod 777 /var/www/html/$domain

# Скачивание и распаковка приложения
curl -L -o /tmp/ztds.7z https://raw.githubusercontent.com/TurboSailor/ztds_sh/main/ztds_v.0.8.4.7z
7z x -o/tmp/ztds /tmp/ztds.7z
cp -a /tmp/ztds/$ztds_version/. /var/www/html/$domain
chmod -R 777 /var/www/html/$domain
chown -R www-data:www-data /var/www/html/$domain

# Генерация случайных ключей и паролей
password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
password_md5=$(echo -n "$password" | md5sum | cut -f1 -d' ')
api_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
postback_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
new_admin_php=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)

mv /var/www/html/$domain/admin.php /var/www/html/$domain/$new_admin_php.php

/bin/cat <<EOM >/var/www/html/$domain/config.php
<?php
/* Конфигурационный файл TDS */
define("INDEX", true);
\$login = 'admin';
\$pass = '$password_md5';
// Другие конфигурации...
?>
EOM

echo "Installation complete. Access your site at http://$domain/$new_admin_php.php"
echo "Admin username: admin"
echo "Admin password: $password"

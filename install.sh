#!/bin/bash

ztds_version='ztds_v.0.8.4'

clear

read -p 'Enter domain name (e.g. site.ru) and press [ENTER]: ' domain </dev/tty


# Установка необходимых пакетов
apt update && apt upgrade -y
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
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
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
systemctl restart php8.3-fpm

# Создание необходимых директорий
mkdir -p /var/lib/php/session
mkdir -p /var/www/html/$domain
chmod 777 /var/lib/php/session
chmod 777 /var/www/html/$domain

# Скачивание и распаковка приложения
curl -L -o /tmp/ztds.7z https://raw.githubusercontent.com/TurboSailor/ztds_sh/main/ztds_v.0.8.4.7z
7z x -o/tmp/ztds /tmp/ztds.7z
cp -a /tmp/ztds/ztds.ru/. /var/www/html/$domain
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
<?php
/********************************************\
| Telegram-канал: https://t.me/z_tds         |
| Вход в админку: admin.php (admin/admin)    |
| Сгенерировать хэш MD5: application/md5.php |
\********************************************/
if(!defined("INDEX")){header('HTTP/1.1 403 Forbidden'); die('403 Forbidden');}
date_default_timezone_set('Europe/Moscow');//временная зона (http://php.net/manual/ru/timezones.php)
\$login = 'admin';//логин
\$pass = '$password_md5';//пароль в md5
\$ip_allow = '';//разрешить доступ к админке только с этого IP (IP в md5). Оставьте пустым если блокировка по IP не нужна
\$auth = 1;//использовать для авторизации куки или сессии (0/1)
\$language = 'ru';//язык (ru/uk/en)
\$api_key = '$api_key';//API ключ ([a-Z0-9] (не забудьте его прописать в api.php)
\$postback_key = '$postback_key';//postback ключ
\$trash = 'http://www.ru';//url куда будем сливать весь мусор (переходы в несуществующие группы). Если \$trash = ''; то будет показана пустая страница
\$ini_folder = 'ini';//название папки с файлами .ini
\$admin_page = '$new_admin_php.php';//название файла админки (если будете менять не забудьте переименовать сам файл!)
\$folder = '';//для работы zTDS в папке укажите ее название, например \$folder = 'folder'; или \$folder = 'folder1/folder2'; если папка в папке
\$keys_folder = 'keys';//название папки для сохранения ключевых слов (http://tds.com/keys)
\$log_folder = 'log';//название папки с логами (http://tds.com/log)
\$log_days = 15;//показывать в админке ссылки на логи за последние 15 дней (должно быть не больше чем \$log_save)
\$log_save = 15;//хранить в БД логи за последние 15 дней
\$log_limit = 500;//показывать первые 500 записей при просмотре логов
\$log_bots = 1;//сохранять в логах ботов (0/1)
\$log_out = 'api,iframe,javascript,show_page_html,show_text';//не сохранять в логах ауты для этих типов редиректа
\$log_ref = 1;//сохранять в логах рефереры (0/1)
\$log_ua = 1;//сохранять в логах юзерагенты (0/1)
\$log_fs = 15;//размер шрифта в логах
\$chart_days = 15;//показывать график за последние 15 дней (должно быть не больше чем \$log_save)
\$chart_weight = 200;//высота графика в пикселях
\$chart_bots = 1;//показывать статистику ботов в графиках (0/1)
\$stat_uniq = 1;//показывать в статистике хиты или уники (0/1)
\$stat_rm = 1;//показывать правое меню (0/1)
\$stat_op = 1;//типы статистики в "Источниках" (0 - хиты+уники+WAP; 1 - хиты+уники+устройства+WAP;)
\$n_cookies = 'cu';//название cookies
\$caplen = 6;//количество букв в каптче (0 - каптча отключена)
\$ipgrabber_token = '';//API ключ от IPGrabber
\$ipgrabber_update = 0;//каждые 360 минут обновлять список ботов IPGrabber (0 - обновление отключено)
\$curl_ua = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0';//useragent для CURL
\$disable_tds = 0;//отключить TDS (0/1)
\$error_log = 1;//сохранение ошибок PHP в файле php_errors.log (0/1)
\$display_errors = 0;//вывод ошибок PHP на экран (0/1)
\$cid_length = 10;//длина CID для постбэка
/*Ниже ничего не изменяйте*/
\$timeout = 60000;
\$debug = 0;
\$empty = '-';
\$version = 'v.0.8.4';
?>
EOM

echo "Installation complete. Access your site at http://$domain/$new_admin_php.php"
echo "Admin username: admin"
echo "Admin password: $password"

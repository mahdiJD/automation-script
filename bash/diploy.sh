#!/bin/bash
# اسکریپت دیپلوی کامل لاراول روی Debian 12

set -e

sed -i '1i192.168.55.55 gitlab.local' /etc/hosts

# بروزرسانی سیستم
apt update && apt upgrade -y

# نصب سرویس‌های لازم
apt install -y git unzip apache2 apt-transport-https lsb-release ca-certificates curl mariadb-server

# فعال‌سازی و استارت Apache
systemctl enable apache2
systemctl start apache2
systemctl status apache2.service

# بررسی پورت 80 (در صورت نیاز)
# ufw allow 80/tcp
# ufw reload

# نصب PHP 8.3 و اکستنشن‌ها
curl -sSL https://packages.sury.org/php/README.txt | bash -x
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury.gpg
apt update && apt upgrade -y
apt install -y php8.3 php-cli php-common php8.3-mysql php8.3-xml php8.3-mbstring php-bcmath php-curl php-zip php-gd

# ریستارت Apache بعد از نصب PHP
systemctl restart apache2

# ساخت دیتابیس و کاربر MariaDB
mariadb -u root <<EOF
CREATE DATABASE evaluation_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'laravel_user'@'localhost' IDENTIFIED BY 'StrongPassword';
GRANT ALL PRIVILEGES ON evaluation_db.* TO 'laravel_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# کلون کردن پروژه
git clone https://gitlab.local/projects-group/evaluation-panel.git /var/www/evaluation-panel
cd /var/www/evaluation-panel
# تغییر شاخه به feature/v1
git checkout feature/v1

# تغییر مالکیت و دسترسی
chmod -R 775 /var/www/evaluation-panel/
chown -R www-data:www-data /var/www/evaluation-panel/

# ساخت VirtualHost
cat <<EOT > /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>
    ServerName your-domain.com
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/evaluation-panel/public

    <Directory /var/www/evaluation-panel/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/laravel_error.log
    CustomLog ${APACHE_LOG_DIR}/laravel_access.log combined
</VirtualHost>
EOT

# فعال‌سازی VirtualHost و ریستارت Apache
a2dissite 000-default.conf
a2ensite laravel.conf
a2enmod rewrite
systemctl reload apache2

# استخراج دایرکتوری vendor (در صورت داشتن zip)
unzip vendor.zip || echo "vendor.zip not found, skipping"

# ساخت فایل .env
cp ./.env.example ./.env
chmod 600 ./.env

# ساخت کلید برنامه
php artisan key:generate

# تنظیم فایل .env
db_config="DB_CONNECTION=mariadb
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=evaluation_db
DB_USERNAME=laravel_user
DB_PASSWORD=StrongPassword
APP_LOCALE=fa
APP_FALLBACK_LOCALE=fa
APP_FAKER_LOCALE=fa
APP_URL="
APP_NAME="Laravel"
APP_ENV="local"
APP_DEBUG="true""

echo "$db_config" > .env

# اجرای مایگریشن‌ها
php artisan migrate --force

# ساخت ادمین
php artisan admin-password

echo "Deployment completed successfully!"

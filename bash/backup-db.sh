#!/bin/bash

PROJECT_DIR="/path/to/laravel/project"
ENV_FILE="$PROJECT_DIR/.env"
BACKUP_DIR="$PROJECT_DIR/backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_METHOD="sudo"

# چک کردن وجود sudo
if ! command -v sudo &>/dev/null; then
    echo "⚠️  دستور sudo روی سیستم نصب نیست."
    read -p "میخوای نصب کنم؟ (y/n): " INSTALL_SUDO
    if [[ "$INSTALL_SUDO" == "y" ]]; then
        echo "🔄 در حال نصب sudo..."
        if [[ -f /etc/debian_version ]]; then
            su - root -c "apt update && apt install -y sudo"
        elif [[ -f /etc/redhat-release ]]; then
            su - root -c "yum install -y sudo"
        else
            echo "❌ سیستم‌عامل پشتیبانی نمی‌شود."
            exit 1
        fi
        
        # بررسی موفقیت نصب
        if ! command -v sudo &>/dev/null; then
            echo "❌ نصب sudo ناموفق بود."
            read -p "میخوای دوباره تلاش کنم؟ (y برای تلاش مجدد / n برای استفاده از su): " RETRY
            if [[ "$RETRY" == "y" ]]; then
                exec "$0" # اجرای مجدد کل اسکریپت
            else
                BACKUP_METHOD="su"
            fi
        fi
    else
        BACKUP_METHOD="su"
    fi
fi

# گرفتن پسورد root یا sudo
if [[ "$BACKUP_METHOD" == "sudo" ]]; then
    read -s -p "🔑 پسورد sudo را وارد کنید: " SUDO_PASS
    echo
else
    echo "برای اجرای دستورات حساس، پسورد root لازم است."
fi

# خواندن اطلاعات DB
DB_NAME=$(grep DB_DATABASE "$ENV_FILE" | cut -d '=' -f2)
DB_USER=$(grep DB_USERNAME "$ENV_FILE" | cut -d '=' -f2)
DB_PASS=$(grep DB_PASSWORD "$ENV_FILE" | cut -d '=' -f2)

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.sql"

# اجرای بکاپ با sudo یا su
if [[ "$BACKUP_METHOD" == "sudo" ]]; then
    echo "$SUDO_PASS" | sudo -S mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE"
else
    su - root -c "mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_FILE"
fi

gzip "$BACKUP_FILE"
echo "✅ بکاپ در مسیر $BACKUP_FILE.gz ذخیره شد."

#!/bin/bash

# ===== تنظیمات =====

# مسیر پایه پروژه (تا یکی قبل از پوشه پروژه)
PROJECT_BASE="/home/admini/www"

# نام پوشه پروژه
PROJECT_NAME="basic-laravel"

# مسیر artisan
ARTISAN="$PROJECT_BASE/$PROJECT_NAME/artisan"

# مسیر لاگ‌ها (بر اساس نام پروژه)
LOG_DIR="/home/admini/laravel_log/$PROJECT_NAME"

# تاریخ امروز (برای نام‌گذاری فایل لاگ)
TODAY=$(date '+%Y-%m-%d')

# مسیر کامل فایل لاگ روزانه
LOG_FILE="$LOG_DIR/schedule-$TODAY.log"

# ===== اجرای کد =====

# ساخت مسیر لاگ اگر وجود نداشت
mkdir -p "$LOG_DIR"

# اجرای Schedule و گرفتن خروجی در یک متغیر
OUTPUT=$(php "$ARTISAN" schedule:run 2>&1)

# بررسی خروجی
if [ -z "$OUTPUT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') No jobs executed" >> "$LOG_FILE"
else
    # نوشتن هر خط خروجی همراه با زمان
    while IFS= read -r line
    do
        echo "$(date '+%Y-%m-%d %H:%M:%S') $line" >> "$LOG_FILE"
    done <<< "$OUTPUT"
fi

# حذف لاگ‌های قدیمی‌تر از 30 روز
find "$LOG_DIR" -type f -name "*.log" -mtime +30 -exec rm {} \;


#!/usr/bin/env bash
# ==============================================================================
# Script Triển Khai Nhanh Bài 2 - IT209 (Chạy trên Ubuntu Droplet / Linux Server)
# ==============================================================================

set -e

echo "=== [BƯỚC 1] Chuẩn bị thư mục Web Root: /var/www/my-web/html/ ==="
sudo mkdir -p /var/www/my-web/html

echo "=== [BƯỚC 2] Sao chép tệp tin HTML vào Web Root ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/html/404.html" ]; then
    sudo cp "$SCRIPT_DIR/html/404.html" /var/www/my-web/html/
    sudo cp "$SCRIPT_DIR/html/index.html" /var/www/my-web/html/
elif [ -f "$SCRIPT_DIR/404.html" ]; then
    sudo cp "$SCRIPT_DIR/404.html" /var/www/my-web/html/
fi

# Thiết lập quyền sở hữu cho Nginx
sudo chown -R www-data:www-data /var/www/my-web
sudo chmod -R 755 /var/www/my-web

echo "=== [BƯỚC 3] Thiết lập cấu hình Nginx Server Block ==="
CONFIG_SOURCE=""
if [ -f "$SCRIPT_DIR/nginx/my-web.conf" ]; then
    CONFIG_SOURCE="$SCRIPT_DIR/nginx/my-web.conf"
elif [ -f "$SCRIPT_DIR/my-web.conf" ]; then
    CONFIG_SOURCE="$SCRIPT_DIR/my-web.conf"
fi

if [ -n "$CONFIG_SOURCE" ]; then
    sudo cp "$CONFIG_SOURCE" /etc/nginx/sites-available/my-web.conf
else
    # Tạo trực tiếp cấu hình nếu file không tồn tại
    sudo bash -c 'cat > /etc/nginx/sites-available/my-web.conf << "EOF"
server {
    listen 80;
    server_name _;

    root /var/www/my-web/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    error_page 404 /404.html;

    location = /404.html {
        root /var/www/my-web/html;
        internal;
    }
}
EOF'
fi

# Kích hoạt site trong sites-enabled
echo "=== [BƯỚC 4] Kích hoạt Site và gỡ bỏ Default Site nếu có ==="
sudo ln -sf /etc/nginx/sites-available/my-web.conf /etc/nginx/sites-enabled/my-web.conf

# Vô hiệu hóa default cũ nếu có xung đột port 80
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
    echo "Đã gỡ bỏ /etc/nginx/sites-enabled/default để ưu tiên my-web."
fi

echo "=== [BƯỚC 5] Kiểm tra cú pháp Nginx và Tải lại dịch vụ ==="
sudo nginx -t
sudo systemctl reload nginx

echo ""
echo "=========================================================="
echo "    TRIỂN KHAI HOÀN TẤT THÀNH CÔNG!"
echo "=========================================================="
echo "Kiểm tra với curl ngay tại máy chủ:"
echo "1. Thử đường dẫn không tồn tại:"
echo "   curl -I http://localhost/invalid-path-demo"
echo ""
echo "2. Thử truy cập trực tiếp /404.html (phải bị chặn internal -> 404):"
echo "   curl -I http://localhost/404.html"
echo "=========================================================="

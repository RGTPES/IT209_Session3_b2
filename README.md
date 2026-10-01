# IT209 - Session 2: Bài 2 - Cấu hình trang lỗi tùy chỉnh (Custom Error Page 404)

## 1. Mục tiêu bài thực hành
- Cấu hình dịch vụ Web Server **Nginx** để phục vụ một trang báo lỗi **404 (Not Found)** tự thiết kế đẹp mắt, thân thiện thay thế cho trang lỗi mặc định của Nginx.
- Bảo mật tệp tin HTML báo lỗi bằng chỉ thị **`internal`** của Nginx nhằm ngăn người dùng internet truy cập trực tiếp vào tệp nguồn `404.html`.

---

## 2. Cấu trúc thư mục

```text
Session2_b2/
├── 404.html                 # Bản sao tệp lỗi 404 ở thư mục gốc
├── my-web.conf              # Bản sao tệp cấu hình Nginx ở thư mục gốc
├── html/
│   ├── 404.html             # Tệp tin HTML báo lỗi 404 tùy biến
│   └── index.html           # Trang chủ mẫu (để kiểm tra hoạt động web)
├── nginx/
│   └── my-web.conf          # Tệp cấu hình Server Block Nginx
├── docker-compose.yml       # Tùy chọn kiểm tra nhanh trên Docker
├── setup.sh                 # Script tự động hóa cài đặt trên máy chủ Linux/Droplet
└── README.md                # Hướng dẫn chi tiết bài làm
```

---

## 3. Nội dung cấu hình Nginx Server Block

Tệp cấu hình tại [my-web.conf](file:///d:/IT209/Session2_b2/nginx/my-web.conf):

```nginx
server {
    listen 80;
    server_name _;

    # 1. Khai báo thư mục Web Root
    root /var/www/my-web/html;
    index index.html index.htm;

    # 2. Xử lý các request thông thường
    location / {
        try_files $uri $uri/ =404;
    }

    # 3. Chỉ định trang lỗi 404 tùy chỉnh
    error_page 404 /404.html;

    # 4. Bảo mật tệp tin báo lỗi bằng chỉ thị internal
    location = /404.html {
        root /var/www/my-web/html;
        internal;
    }
}
```

### Giải thích chi tiết các chỉ thị:
- **`error_page 404 /404.html;`**: Khi máy chủ gặp lỗi `404 Not Found` (tài nguyên không tồn tại), Nginx sẽ điều hướng yêu cầu nội bộ sang URI `/404.html`.
- **`location = /404.html { ... }`**: Sử dụng toán tử `=` (Exact match) để khớp chính xác đường dẫn `/404.html`.
- **`internal;`**: 
  - Chỉ cho phép các request nội bộ (internal requests) được sinh ra từ Nginx (như lệnh `error_page`, subrequests, hoặc rewrite) truy cập vào location này.
  - Ngăn chặn triệt để client/người dùng từ internet gửi request trực tiếp `http://<IP>/404.html` qua trình duyệt hoặc curl. Nếu cố tình truy cập trực tiếp, Nginx sẽ từ chối và trả về `404 Not Found`.

---

## 4. Các bước triển khai trên máy chủ (Droplet / Ubuntu)

### Cách 1: Sử dụng script tự động hóa
Chạy lệnh sau trên thư mục dự án:
```bash
chmod +x setup.sh
./setup.sh
```

### Cách 2: Triển khai thủ công từng bước

#### Bước 1: Tạo thư mục Web Root và tải mã nguồn HTML
```bash
sudo mkdir -p /var/www/my-web/html
# Sao chép tệp 404.html và index.html vào thư mục
sudo cp html/404.html /var/www/my-web/html/
sudo cp html/index.html /var/www/my-web/html/

# Phân quyền cho www-data
sudo chown -R www-data:www-data /var/www/my-web
sudo chmod -R 755 /var/www/my-web
```

#### Bước 2: Thiết lập cấu hình Nginx Server Block
```bash
sudo cp nginx/my-web.conf /etc/nginx/sites-available/my-web.conf
sudo ln -sf /etc/nginx/sites-available/my-web.conf /etc/nginx/sites-enabled/my-web.conf

# (Tùy chọn) Gỡ bỏ default site cũ nếu bị xung đột port 80:
sudo rm -f /etc/nginx/sites-enabled/default
```

#### Bước 3: Kiểm tra cú pháp và kích hoạt
```bash
# Kiểm tra cú pháp cấu hình
sudo nginx -t

# Tải lại dịch vụ Nginx
sudo systemctl reload nginx
```

---

## 5. Kiểm tra kết quả (Testing)

### Lệnh 1: Truy cập một đường dẫn không tồn tại
```bash
curl -I http://<IP_ADDRESS_DROPLET>/invalid-path-demo
```
**Kết quả mong đợi:**
- Trả về mã trạng thái: **`HTTP/1.1 404 Not Found`**.
- Khi xem nội dung qua trình duyệt hoặc `curl http://<IP_ADDRESS_DROPLET>/invalid-path-demo`, hiển thị giao diện HTML báo lỗi tùy biến (chứa thông báo thân thiện và mã lỗi 404).

### Lệnh 2: Truy cập trực tiếp tệp tin lỗi 404.html
```bash
curl -I http://<IP_ADDRESS_DROPLET>/404.html
```
**Kết quả mong đợi:**
- Trả về mã trạng thái: **`HTTP/1.1 404 Not Found`** (do cơ chế `internal` của Nginx chặn truy cập trực tiếp từ người dùng bên ngoài).

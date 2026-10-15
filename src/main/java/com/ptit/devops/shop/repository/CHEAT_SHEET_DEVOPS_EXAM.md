# ==============================================================================
# BÍ KÍP THI THỰC HÀNH DEVOPS - "CẦM TAY CHỈ VIỆC TỪ A ĐẾN Z"
# ==============================================================================
# ĐÃ CẬP NHẬT CHÍNH XÁC THÔNG TIN VPS & DOCKER HUB CỦA BẠN ĐỂ ĐI THI
# ==============================================================================

---

## 📌 BẢNG THÔNG TIN TÀI KHOẢN CỦA BẠN (DÙNG SUỐT BÀI THI)

| Thông số | Giá trị thực tế của bạn | Lưu ý quan trọng |
| :--- | :--- | :--- |
| **Docker Hub Username** | `anhsdocker` | Dùng làm prefix cho image & điền GitHub Secrets |
| **Docker Hub Password** | `docker123@` | Điền vào secret `DOCKER_PASSWORD` |
| **Docker Hub Email** | `kun8742@gmail.com` | **Phải vào Gmail bấm Verify link kích hoạt** |
| **VPS IP (Host)** | `221.121.3.94` | Cổng SSH: 22. Điền vào secret `VPS_HOST` |
| **VPS User Root** | `root` | Dùng đăng nhập lần đầu để tạo user bài thi |
| **VPS Root Password** | `Vpstest123123@` | Mật khẩu truy cập root VPS |
| **User bài thi yêu cầu**| `devops_student` | User bạn sẽ tạo theo đề bài |
| **Tên Image Docker** | `anhsdocker/devops-backend:latest` | Tên image đẩy lên Docker Hub & deploy |
| **Link kiểm tra API** | `http://221.121.3.94:8080/api/employees/count` | Endpoint chấm điểm bài 4 |

---

## 🎯 TỔNG QUAN ĐỀ THI & PHÂN BỔ ĐIỂM (10 ĐIỂM)
1. **Bài 1 (2.0 đ): Quản trị VPS Linux**
   - Đăng nhập SSH `root@221.121.3.94`.
   - Kiểm tra `whoami`, `id`.
   - Tạo user `devops_student`, cấp sudo, thêm vào nhóm `docker`.
   - Đổi sang `devops_student`, tạo thư mục `devops-exam`, file `info.txt`, phân quyền `chmod 644`.
2. **Bài 2 (2.0 đ): Docker & Docker Compose trên VPS**
   - Điền file `Dockerfile` cho Spring Boot (Java 17).
   - Điền file `docker-compose.yml` (MySQL + Backend Spring Boot).
   - Chạy test, kiểm tra `docker ps`, `docker logs backend-app`.
3. **Bài 3 (1.5 đ): Git & GitHub**
   - Tạo repo GitHub cá nhân: `devops-exam-<MSV>` (VD: `devops-exam-b20dccn001`).
   - Push code `main`, tạo nhánh `feature/employee-count`.
   - Tạo conflict cố ý trong `README.md`, giải quyết xung đột, merge vào `main`.
   - Kiểm tra cây log `git log --oneline --graph --all`.
4. **Bài 4 (4.5 đ): Viết API & Triển khai CI/CD GitHub Actions**
   - Viết API `GET /api/employees/count`.
   - Tạo pipeline `.github/workflows/deploy.yml` tự động build và deploy lên `221.121.3.94`.
   - Cài đặt 5 Secrets trên GitHub.
   - Gọi `curl http://221.121.3.94:8080/api/employees/count` chứng minh hoạt động.
   - Trả lời 4 câu hỏi lý thuyết.

---

# ⚠️ BƯỚC 0: CÀI ĐẶT SẴN DOCKER TRÊN VPS (LÀM TRƯỚC TỐI NAY)

Mở **PowerShell** trên Windows của bạn và chạy:

```bash
ssh root@221.121.3.94
```
- Nếu hỏi `yes/no`: gõ `yes` rồi Enter.
- Mật khẩu: Paste `Vpstest123123@` (click chuột phải 1 cái rồi bấm Enter).

Khi đã vào được VPS (`root@FinalTest:~#`), chạy lệnh cài Docker:
```bash
apt-get update -y && curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
```

Kiểm tra Docker đã sống:
```bash
docker --version
docker compose version
```

---

# BƯỚC 1: QUẢN TRỊ VPS LINUX (BÀI 1 - 2.0 ĐIỂM)

### 1.1. Đăng nhập VPS và kiểm tra (0.5 điểm)
```bash
ssh root@221.121.3.94
whoami
id
```
*(Chụp ảnh màn hình)*

### 1.2. Tạo user Linux và phân quyền nhóm Docker (0.5 điểm)
```bash
# Tạo user devops_student (nhập mật khẩu dễ nhớ, vd: devops123, còn lại bấm Enter hết)
adduser devops_student

# Cấp quyền sudo và quyền chạy Docker
usermod -aG sudo devops_student
usermod -aG docker devops_student

# Kiểm tra lại nhóm của devops_student
id devops_student
```

> **Giải thích câu hỏi phụ đề bài**:  
> *Vì sao thành viên nhóm docker có quyền tương đương quyền quản trị rất cao (root)?*  
> 👉 **Trả lời**: Vì Docker daemon (`dockerd`) chạy dưới quyền `root`. Bất kỳ user nào thuộc nhóm `docker` đều có thể mount thư mục gốc `/` của hệ thống host vào bên trong container thông qua tham số `-v /:/host`, từ đó có thể đọc/ghi, sửa đổi hoặc xóa mọi file hệ thống nhạy cảm của Linux (như `/etc/shadow`, `/etc/sudoers`) mà không cần mật khẩu root.

### 1.3. Quản lý file và thư mục (1.0 điểm)
```bash
# Chuyển sang user devops_student
su - devops_student

# Kiểm tra lại
whoami

# Tạo thư mục devops-exam và vào thư mục
mkdir devops-exam
cd devops-exam

# Tạo file info.txt
nano info.txt
```
Nội dung file `info.txt`:
```text
Họ và tên: <Điền Họ Tên Bạn>
Mã sinh viên: <Điền MSV của bạn>
GitHub Repo: https://github.com/<your-github>/devops-exam-<MSV>
Docker Hub: anhsdocker
VPS IP: 221.121.3.94
```
*(Nhấn `Ctrl + O` -> `Enter` để lưu, `Ctrl + X` để thoát).*

```bash
# Xem nội dung file
cat info.txt

# Phân quyền cho file (chủ sở hữu đọc ghi, người khác chỉ đọc)
chmod 644 info.txt

# Kiểm tra quyền chi tiết
ls -la info.txt
```
*(Chụp ảnh màn hình terminal thể hiện user devops_student, file info.txt và quyền ls -la)*

---

# BƯỚC 2: DOCKER & DOCKER COMPOSE TRÊN VPS (BÀI 2 - 2.0 ĐIỂM)

Đề bài cung cấp sẵn khung Dockerfile và docker-compose.yml mẫu. Đây là nội dung chuẩn đã điền đầy đủ:

### 2.1. File `Dockerfile` hoàn chỉnh:
*(Tạo tại thư mục gốc của code `RestAPI_Session04`)*

```dockerfile
# Sử dụng JDK 17 slim làm image nền phù hợp với dự án
FROM openjdk:17-jdk-slim

# Khai báo thư mục làm việc bên trong container
WORKDIR /app

# Copy file jar được build bởi Gradle vào container
COPY build/libs/*SNAPSHOT.jar app.jar

# Khai báo cổng ứng dụng lắng nghe
EXPOSE 8080

# Lệnh khởi chạy ứng dụng Spring Boot
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 2.2. File `docker-compose.yml` hoàn chỉnh:
*(Tạo tại thư mục gốc của code trên máy local hoặc trên VPS)*

```yaml
version: '3.8'

services:
  mysql-db:
    image: mysql:8.0
    container_name: mysql-cntt3
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: db_cntt3_api_ss4
      MYSQL_USER: devops_user
      MYSQL_PASSWORD: devops_password
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: [ "CMD", "mysqladmin", "ping", "-h", "localhost" ]
      timeout: 5s
      retries: 10
      interval: 5s

  backend:
    build:
      context: ../../../../../../../../../../Session 14
      dockerfile: Dockerfile
    container_name: backend-app
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql-db:3306/db_cntt3_api_ss4?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: root
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    depends_on:
      mysql-db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  mysql_data:
```

### 2.3. Lệnh kiểm tra Docker cần chụp ảnh minh chứng:
```bash
# Khởi động dịch vụ
docker compose up -d --build

# Xem các container đang chạy
docker ps

# Xem log backend
docker logs -f backend-app

# Dừng dịch vụ
docker compose down
```

---

# BƯỚC 3: GIT & GITHUB (BÀI 3 - 1.5 ĐIỂM)

Thực hiện trên máy tính của bạn tại thư mục dự án `RestAPI_Session04`:

### 3.1. Khởi tạo Git & Push lên GitHub:
1. Vào GitHub cá nhân -> Bấm **New Repository**.
2. Đặt tên: `devops-exam-<MSV>` (Ví dụ: `devops-exam-b20dccn001`), chọn **Public**.
3. Mở Terminal tại thư mục `RestAPI_Session04`:
```bash
git init
git branch -M main
git add .
git commit -m "feat: initial commit base source"
git remote add origin https://github.com/<YOUR_GITHUB_USER>/devops-exam-<MSV>.git
git push -u origin main
```

### 3.2. Tạo nhánh chức năng:
```bash
git checkout -b feature/employee-count

# Sau khi sửa code ở Bài 4 xong:
git add .
git commit -m "feat: add get employee count API"
git push -u origin feature/employee-count
```

### 3.3. Tạo và xử lý Merge Conflict (0.5 điểm):
```bash
# 1. Chuyển về main và sửa 1 dòng
git checkout main
echo "Update from main branch" >> README.md
git add README.md
git commit -m "update readme on main"

# 2. Chuyển sang feature và sửa đúng dòng đó nội dung khác
git checkout feature/employee-count
echo "Update from feature branch" >> README.md
git add README.md
git commit -m "update readme on feature"

# 3. Merge feature vào main (sẽ báo CONFLICT)
git checkout main
git merge feature/employee-count

# 4. Mở README.md xoá các dấu <<<<<<< HEAD, =======, >>>>>>> và giữ lại nội dung bạn muốn

# 5. Commit kết quả giải quyết xung đột
git add README.md
git commit -m "fix: resolve merge conflict between main and feature"
git push origin main

# 6. Kiểm tra cây lịch sử đồ thị:
git log --oneline --graph --all
```
*(Chụp ảnh màn hình cây git log này lại)*

---

# BƯỚC 4: VIẾT API MỚI & TRIỂN KHAI CI/CD (BÀI 4 - 4.5 ĐIỂM)

### 4.1. Code API đếm nhân viên: `GET /api/employees/count` (1.0 điểm)

#### File 1: `src/main/java/ra/demo/model/entity/Employee.java`
```java
package ra.demo.model.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "employees")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Employee {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String email;
}
```

#### File 2: `src/main/java/ra/demo/repository/EmployeeRepository.java`
```java
package ra.demo.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import ra.demo.model.entity.Employee;

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {
}
```

#### File 3: `src/main/java/ra/demo/controller/EmployeeController.java`
```java
package ra.demo.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ra.demo.repository.EmployeeRepository;

@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeRepository employeeRepository;

    @GetMapping("/count")
    public ResponseEntity<Long> getEmployeeCount() {
        long count = employeeRepository.count();
        return ResponseEntity.ok(count);
    }
}
```

---

### 4.2. File GitHub Actions Workflow: `.github/workflows/deploy.yml` (1.5 điểm)

Tạo file tại `.github/workflows/deploy.yml` trong project:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ "main" ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build with Gradle
        run: |
          chmod +x ./gradlew
          ./gradlew clean bootJar -x test

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/devops-backend:latest

      - name: Deploy to VPS via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          password: ${{ secrets.VPS_PASSWORD }}
          script: |
            cd ~/devops-exam
            docker pull ${{ secrets.DOCKER_USERNAME }}/devops-backend:latest
            docker compose down
            docker compose up -d
            docker image prune -f
```

---

### 4.3. Cài đặt 5 Secrets trên GitHub (BẮT BUỘC):
Vào Repo GitHub -> **Settings** -> **Secrets and variables** -> **Actions** -> Bấm **New repository secret**:

1. `DOCKER_USERNAME` = `anhsdocker`
2. `DOCKER_PASSWORD` = `docker123@`
3. `VPS_HOST` = `221.121.3.94`
4. `VPS_USER` = `devops_student` *(hoặc `root`)*
5. `VPS_PASSWORD` = Mật khẩu của user đó *(nếu là `root` thì là `Vpstest123123@`, nếu là `devops_student` thì là mật khẩu bạn đặt lúc tạo)*

---

### 4.4. Tạo sẵn file `docker-compose.yml` trên VPS (Tại `~/devops-exam`):
Đăng nhập SSH vào VPS bằng user `devops_student`:
```bash
ssh devops_student@221.121.3.94
cd ~/devops-exam
nano docker-compose.yml
```
Dán nội dung sau vào:
```yaml
version: '3.8'

services:
  mysql-db:
    image: mysql:8.0
    container_name: mysql-cntt3
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: db_cntt3_api_ss4
      MYSQL_USER: devops_user
      MYSQL_PASSWORD: devops_password
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 5s
      retries: 10
      interval: 5s

  backend:
    image: anhsdocker/devops-backend:latest
    container_name: backend-app
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql-db:3306/db_cntt3_api_ss4?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: root
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    depends_on:
      mysql-db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  mysql_data:
```
*(Nhấn `Ctrl + O` -> `Enter` để lưu, `Ctrl + X` để thoát).*

---

### 4.5. Kiểm chứng kết quả (1.5 điểm):
Khi push code lên GitHub `main`, tab Actions chạy xong xanh lá cây:
Mở terminal máy bạn gõ:
```bash
curl http://221.121.3.94:8080/api/employees/count
```
Kết quả trả về: `0` (hoặc số lượng bản ghi tương ứng).

---

# 📝 ĐÁP ÁN 4 CÂU HỎI LÝ THUYẾT (0.5 ĐIỂM)

1. **Sự kiện nào kích hoạt CI/CD?**
   - 👉 *Trả lời*: Sự kiện `git push` lên nhánh `main` (được khai báo trong `on: push: branches: [ "main" ]`).
2. **Vì sao phải sử dụng GitHub Secrets?**
   - 👉 *Trả lời*: Để bảo vệ an toàn các thông tin nhạy cảm (mật khẩu VPS, token Docker Hub, IP máy chủ). Nếu để lộ ra mã nguồn công khai, kẻ tấn công có thể chiếm đoạt server VPS và Docker Hub của bạn.
3. **Nếu build thất bại thì có nên tiếp tục deploy không?**
   - 👉 *Trả lời*: **Tuyệt đối không**. Nếu build/test lỗi mà vẫn deploy, phiên bản lỗi sẽ đè lên ứng dụng đang chạy, làm sập toàn bộ dịch vụ của người dùng. GitHub Actions sẽ tự động dừng quy trình ngay tại bước lỗi để bảo vệ hệ thống.
4. **Làm thế nào để xác nhận VPS đang chạy đúng phiên bản mới?**
   - 👉 *Trả lời*:
     1. Gõ `docker ps` xem cột `CREATED` hoặc `STATUS` vừa khởi động lại vài phút trước.
     2. Gõ `docker images` kiểm tra IMAGE ID hoặc tag mới nhất vừa được kéo về.
     3. Xem log bằng `docker logs -f backend-app` để kiểm tra log Spring Boot khởi động phiên bản mới.
     4. Gọi `curl http://221.121.3.94:8080/api/employees/count` để xác nhận endpoint mới phản hồi thành công.

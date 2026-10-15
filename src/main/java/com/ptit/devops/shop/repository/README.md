# RestAPI Session04 — Spring Boot + Docker + CI/CD VPS

Thứ tự làm từ đầu đến cuối: VPS -> Docker -> GitHub Actions -> Verify.
Repo: `https://github.com/An256122006/PTIT_CNTT1_IT209_Session14.git`, nhánh `master`.
Path chuẩn trên VPS: `~/devops-exam/PTIT_CNTT1_IT209_Session14` (khớp `.github/workflows/deploy.yml:71`).

## 1. Tổng quan

- Spring Boot `4.0.6`, Java `17` (`build.gradle:11-15`), Gradle Wrapper
- MySQL `8.0`, JPA `ddl-auto=update` (`application.properties:12`)
- Port app `8080` (`application.properties:2`, `docker-compose.yml:25`)
- Image Docker Hub: `trongan2006/devops-exam-app` (`.github/workflows/deploy.yml:10`)

File quan trọng:

| File | Vai trò |
|---|---|
| `Dockerfile:1-9` | Runtime `eclipse-temurin:17-jre`, copy `build/libs/app.jar` |
| `docker-compose.yml:1-36` | 2 service `mysql` + `backend`, `backend` có cả `build:` và `image:` |
| `.env.example:1-19` | Mẫu biến môi trường, copy thành `.env` khi chạy local |
| `.env` | File thật, đã ignore (`.gitignore:40`), không commit |
| `src/main/resources/application.properties:1-17` | Đọc config từ biến môi trường, fallback chạy local |
| `.github/workflows/deploy.yml:1-98` | Pipeline build + push + SSH deploy VPS |

## 2. Yêu cầu

- JDK 17, Docker + Compose plugin, Git
- Tài khoản Docker Hub + VPS Ubuntu (mở port `22, 8080`)

## Bước 0 — Tạo các file Docker/CI (trong VS Code, ở root project)

### 0.1. Tạo `Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY build/libs/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Lưu ý: phải `./gradlew clean bootJar -x test` trước để có `build/libs/app.jar` (`build.gradle:39-41` đặt tên jar là `app.jar`).

### 0.2. Tạo `docker-compose.yml`

```yaml
services:
  mysql:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${MYSQL_DATABASE:-employee_db}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: [ "CMD-SHELL", "mysqladmin ping -h localhost -u root -p\"$$MYSQL_ROOT_PASSWORD\"" ]
      interval: 10s
      timeout: 5s
      retries: 10

  backend:
    build:
      context: ../../../../../../../../../..
      dockerfile: Dockerfile
    image: ${DOCKER_IMAGE}
    restart: unless-stopped
    ports:
      - "${SERVER_PORT:-8080}:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/${MYSQL_DATABASE:-employee_db}?createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true&useSSL=false
      SPRING_DATASOURCE_USERNAME: ${MYSQL_USER}
      SPRING_DATASOURCE_PASSWORD: ${MYSQL_PASSWORD}
      SERVER_PORT: 8080
    depends_on:
      mysql:
        condition: service_healthy

volumes:
  mysql_data:
```

`backend` cần cả `build:` (để chạy local `up --build`) và `image:` (để VPS `pull` image Docker Hub).
```
docker compose up -d --build
docker compose ps
curl http://localhost:8080/api/employees/count
```
### 0.3. Tạo `.env.example` rồi copy thành `.env`

`.env.example` (được commit):

```
MYSQL_DATABASE=employee_db
MYSQL_ROOT_PASSWORD=change_me_root_password
MYSQL_USER=change_me_user
MYSQL_PASSWORD=change_me_password
DOCKER_IMAGE=restapi-session04:latest
SERVER_PORT=8080
PAGE_SIZE_PRODUCTS=3
```

```bash
cp .env.example .env
```

`.env` thật (không commit, đã ignore ở `.gitignore:40`), sửa giá trị local:

```
MYSQL_DATABASE=db_cntt3_api_ss4
MYSQL_ROOT_PASSWORD=1234$
MYSQL_USER=app_user
MYSQL_PASSWORD=1234$
DOCKER_IMAGE=restapi-session04:latest
SERVER_PORT=8080
PAGE_SIZE_PRODUCTS=3
```

### 0.4. Tạo `.github/workflows/deploy.yml`

```yaml
name: CI/CD - Build and Deploy to VPS

on:
  push:
    branches: [master]
  workflow_dispatch:

env:
  IMAGE_NAME: trongan2006/devops-exam-app

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - name: Checkout source code
        uses: actions/checkout@v4
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4
      - name: Build Spring Boot
        run: chmod +x gradlew && ./gradlew clean bootJar -x test
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - name: Build and push Docker image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            ${{ env.IMAGE_NAME }}:latest
            ${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    timeout-minutes: 8
    steps:
      - name: Deploy to VPS via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          port: 22
          timeout: 30s
          command_timeout: 5m
          script: |
            set -e
            cd ~/devops-exam/PTIT_CNTT1_IT209_Session14
            GIT_TERMINAL_PROMPT=0 git pull --ff-only origin master
            cat > .env <<'EOF'
            MYSQL_DATABASE=${{ secrets.MYSQL_DATABASE }}
            MYSQL_ROOT_PASSWORD=${{ secrets.MYSQL_ROOT_PASSWORD }}
            MYSQL_USER=${{ secrets.MYSQL_USER }}
            MYSQL_PASSWORD=${{ secrets.MYSQL_PASSWORD }}
            DOCKER_IMAGE=${{ env.IMAGE_NAME }}:${{ github.sha }}
            SERVER_PORT=8080
            PAGE_SIZE_PRODUCTS=3
            EOF
            chmod 600 .env
            docker compose pull
            docker compose up -d --remove-orphans
            docker ps
```

Xong Bước 0 mới sang Bước 1 (VPS) bên dưới.

## Bước 1 — SSH vào VPS mới

```bash
ssh root@VPS_IP
apt update && apt upgrade -y
apt install -y git curl
```

## Bước 2 — Cài Docker + Compose trên VPS

```bash
curl -fsSL https://get.docker.com | sh
docker --version
docker compose version
```

Tạo user deploy (khỏi dùng root):

```bash
adduser devops
usermod -aG sudo,docker devops

```

Mở firewall:

```bash
sudo apt update
sudo apt install ufw -y
ufw allow 22
ufw allow 8080
ufw enable
```

## Bước 3 — Nạp SSH key cho CI

Chạy ở máy local (VS Code):

```powershell
ssh-keygen -t ed25519 -C "github-actions"
# sinh ~/.ssh/id_ed25519 (private) + id_ed25519.pub (public)
ssh-copy-id devops@VPS_IP
ssh -i ~/.ssh/id_ed25519 devops@VPS_IP  # test ok là được
ls -la ~/.ssh/
cat ~/.ssh/github_actions_vps
```

- `-C "github-actions"` chỉ là comment để nhớ key dùng cho việc gì.
- Public key (`ssh-ed25519 AAAA...`) -> `~/.ssh/authorized_keys` trên VPS.
- Private key (`id_ed25519`, từ `-----BEGIN...` đến `-----END...`) -> Secret `VPS_SSH_KEY` trên GitHub.

## Bước 4 — Clone code đúng path trên VPS

```bash
ssh devops@VPS_IP
mkdir -p ~/devops-exam
git clone https://github.com/An256122006/PTIT_CNTT1_IT209_Session14.git ~/devops-exam/PTIT_CNTT1_IT209_Session14
cd ~/devops-exam/PTIT_CNTT1_IT209_Session14
git checkout master
```

Sai path là job `deploy` fail ở `STEP 2: ENTER PROJECT`.

## Bước 5 — Docker Hub + GitHub Secrets

1. Tạo repo public `trongan2006/devops-exam-app`.
2. Tạo Access Token Read/Write, test ở máy local:
```bash
docker logout
docker login -u trongan2006
```
3. GitHub Repo > Settings > Secrets > Actions, thêm đủ:

| Secret | Giá trị |
|---|---|
| `DOCKERHUB_USERNAME` | `trongan2006` |
| `DOCKERHUB_TOKEN` | `dckr_pat_...` (paste bằng tay, không commit) |
| `VPS_HOST` | IP VPS, vd `123.30.45.67` (không thêm `http://`) |
| `VPS_USER` | `devops` |
| `VPS_SSH_KEY` | toàn bộ private key `id_ed25519` |
| `MYSQL_DATABASE` | `db_cntt3_api_ss4` |
| `MYSQL_ROOT_PASSWORD` | `1234$` |
| `MYSQL_USER` | `app_user` |
| `MYSQL_PASSWORD` | `1234$` |

## Bước 6 — Chạy Docker local trước khi đẩy

```bash
# Clone (nếu chưa có)
git clone https://github.com/An256122006/PTIT_CNTT1_IT209_Session14.git
cd PTIT_CNTT1_IT209_Session14
git checkout master

# Tạo .env từ mẫu, local để DOCKER_IMAGE=restapi-session04:latest
cp .env.example .env

# Build jar (bắt buộc vì Dockerfile COPY build/libs/app.jar)
sudo apt update
sudo apt install openjdk-17-jdk -y
chmod +x gradlew
./gradlew clean bootJar -x test

# Chạy compose (dùng --build, KHÔNG dùng pull ở local)
docker compose up -d --build
docker compose ps
docker compose logs backend --tail=50
```

Nếu báo `port is already allocated` (vd `campus-hub-backend` đang chiếm `8080`), đổi trong `.env`:
```
SERVER_PORT=8081
```
rồi `docker compose up -d`.

Dừng / xóa:
```bash
docker compose down
docker compose down -v  # xóa luôn data MySQL
```

## Bước 7 — Đẩy là tự deploy lên VPS

```bash
git add -A
git commit -m "deploy"
git push origin master
```

Pipeline (`deploy.yml`): checkout > setup JDK 17 > `./gradlew clean bootJar -x test` (bỏ test để không cần MySQL trên CI) > login Docker Hub > push 2 tag `latest` + `sha` > SSH vào VPS `git pull --ff-only origin master` > viết lại `.env` từ Secrets (dùng `<<'EOF'` để `$` trong `1234$` không bị expand) > `chmod 600 .env` > `docker compose pull` > `docker compose up -d --remove-orphans` > `docker ps`.
Xem tiến trình ở tab Actions.

## Bước 8 — Verify trên VPS

```bash
cd ~/devops-exam/PTIT_CNTT1_IT209_Session14
cat .env
docker ps
docker compose ps
docker compose logs backend --tail=100
curl -f http://localhost:8080/api/employees/count
curl -f http://localhost:8080/api/v1/categories
curl -f "http://localhost:8080/api/v1/products?page=1"
```

API đầy đủ:

| Method | URL |
|---|---|
| GET | `http://localhost:8080/api/employees/count` |
| GET | `http://localhost:8080/api/v1/categories` |
| POST | `http://localhost:8080/api/v1/categories` |
| PUT | `http://localhost:8080/api/v1/categories/{cateId}` |
| DELETE | `http://localhost:8080/api/v1/categories/{cateId}` |
| GET | `http://localhost:8080/api/v1/products?page=1` |
| GET | `http://localhost:8080/api/v1/products/list-products?page=1&orderBy=proId&sortBy=asc` |
| POST | `http://localhost:8080/api/v1/products` |

## Lỗi hay gặp

| Lỗi | Nguyên nhân / sửa |
|---|---|
| `pull access denied for restapi-session04` | Chạy `pull` ở local trong khi image chỉ tồn tại local. Local dùng `up -d --build`, `pull` chỉ dùng trên VPS khi `DOCKER_IMAGE` là image Docker Hub có thật (`docker-compose.yml:19-22` đã có `build:`). |
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | Port bị container khác giữ. Đổi `SERVER_PORT=8081` trong `.env` hoặc `docker stop <container-kia>`. |
| `curl .../api/... -> 404` | `/api/...` là placeholder, không phải endpoint. Dùng URL đầy đủ ở Bước 8. `404` nghĩa là app đã chạy, chỉ sai đường dẫn. |
| CI không chạy | Push nhầm nhánh. Pipeline trigger `branches: [master]`. |
| `git pull` fail trên VPS | Do commit trực tiếp trên VPS hoặc sai path/nhánh. Kiểm tra `git status`, path `~/devops-exam/PTIT_CNTT1_IT209_Session14`, dùng `--ff-only origin master`. |

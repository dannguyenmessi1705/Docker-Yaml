# Jenkins Deploy CI/CD
## 1. Giới thiệu
Jenkins là một công cụ tự động hóa mã nguồn mở, giúp tự động hóa quy trình phát triển phần mềm. Nó hỗ trợ tích hợp liên tục (CI) và triển khai liên tục (CD), cho phép các nhóm phát triển xây dựng, kiểm tra và triển khai ứng dụng một cách nhanh chóng và hiệu quả.

## 2. Cài đặt Jenkins
Để cài đặt Jenkins, bạn có thể làm theo các bước sau:
1. Chuẩn bị file Dockerfile cho Jenkins để cài đặt Docker và Maven trước khi chạy Jenkins.
```dockerfile
FROM jenkins/jenkins:lts

## Chạy Jenkins với quyền root (để cài đặt Docker và Maven)
USER root 

## Cài đặt Maven
RUN apt-get update && apt-get install -y maven

## Cài đặt Docker
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    sudo && \
    curl -fsSL https://get.docker.com -o install-docker.sh && \
    sudo sh install-docker.sh && \
    sudo usermod -a -G docker jenkins
```

2. Sử dụng docker-compose để khởi động Jenkins, SonarQube và các services cần thiết.
```yaml
services:
  jenkins: # Jenkins service
    build:  # Lệnh để build Jenkins image từ Dockerfile
      context: . # Đường dẫn đến thư mục chứa Dockerfile
      dockerfile: Dockerfile # Tên file
    container_name: jenkins-container # Tên container
    ports: 
      - "8088:8080" # Jenkins web UI port
      - "50000:50000" # Jenkins agent port
    volumes:
      - ./data/jenkins:/var/jenkins_home # Mount các cấu hình của Jenkins
      - //var/run/docker.sock:/var/run/docker.sock # Mount Docker socket để Jenkins có thể chạy Docker commands
    networks:
      - jenkinsnet # Tên mạng cho các services
    environment:
      JENKINS_OPTS: --httpPort=8080 # Jenkins HTTP port

  sonarqube: # SonarQube service
    container_name: sonarqube # SonarQube container
    image: sonarqube:community # Tên SonarQube image
    depends_on: # SonarQube phụ thuộc vào db
      - db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonarqube?useSSL=false # Cấu hình kết nối đến PostgreSQL database
      SONAR_JDBC_USERNAME: sonar # Tên user cho SonarQube
      SONAR_JDBC_PASSWORD: sonar # Mật khẩu cho SonarQube
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: "true" # Tắt bật kiểm tra bootstrap của Elasticsearch
   ports:
      - "9000:9000" # SonarQube web UI port
    volumes:
      - ./sonarqube_conf:/opt/sonarqube/conf # Mount cấu hình SonarQube
      - ./sonarqube_data:/opt/sonarqube/data # Mount dữ liệu SonarQube
      - ./sonarqube_extensions:/opt/sonarqube/sonarqube_extensions # Mount dữ liệu SonarQube
      - ./sonarqube_logs:/opt/sonarqube/sonarqube_logs # Mount dữ liệu SonarQube
      - ./sonarqube_temp:/opt/sonarqube/temp # Mount dữ liệu SonarQube
    networks:
      - jenkinsnet # Tên mạng cho các services
  
  db: # PostgreSQL database service là SonarQube sử dụng
    container_name: db # PostgreSQL database
    image: postgres:13 # Tên PostgreSQL image
    environment:
      POSTGRES_USER: sonar # Tên user cho PostgreSQL
      POSTGRES_PASSWORD: sonar # Mật khẩu cho PostgreSQL
      POSTGRES_DB: sonarqube # Tên database cho SonarQube
    restart: unless-stopped # Cấu hình khởi động lại container nếu nó dừng lại
    volumes:
      - ./sonarqube_db:/var/lib/postgresql # Mount dữ liệu PostgreSQL
      - ./sonarqube_db_data:/var/lib/postgresql/data # Mount dữ liệu PostgreSQL
    networks:
      - jenkinsnet # Tên mạng cho các services

networks:
  jenkinsnet:
    driver: bridge # Tên mạng cho các services
```

3. Chạy lệnh sau để khởi động các services:
```bash
docker-compose up -d
```

## 3. Cấu hình các services và cài đặt plugin cho Jenkins
### 3.1. Cấu hình SonarQube
1. Để cấu hình SonarQube, bạn cần truy cập vào địa chỉ `http://localhost:9000` và đăng nhập với tài khoản mặc định: `admin/admin`. Sau đó, bạn có thể thay đổi mật khẩu và cấu hình các dự án cần phân tích.

2. Tạo một token cho Jenkins để sử dụng trong quá trình tích hợp với SonarQube. Bạn có thể tạo token bằng cách vào `Administration` -> `Security` -> `Users`. Chọn user `admin` và tạo token mới. Lưu lại token này để sử dụng trong Jenkins.

### 3.2. Cài đặt plugin cho Jenkins
1. Để cài đặt plugin cho Jenkins, bạn cần truy cập vào địa chỉ `http://localhost:8088` và đăng nhập với password mặc định lấy từ file `jenkins_home/secrets/initialAdminPassword` trong thư mục dữ liệu của Jenkins.

2. Sau khi đăng nhập, bạn có thể cài đặt các plugin cần thiết cho Jenkins bằng cách vào `Manage Jenkins` -> `Manage Plugins`. Tại đây, bạn có thể tìm kiếm và cài đặt các plugin như:
   - Docker
   - Pipeline: Stage View
   - Docker Pipeline
   - Docker API
   - docker-build-step
   - CloudBees Docker Build and Publish
   - Eclipse Temurin installer
   - SonarQube Scanner
   - Sonar Quality Gates

3. Restart Jenkins sau khi cài đặt các plugin.
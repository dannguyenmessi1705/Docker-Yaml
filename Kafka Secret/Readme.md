# Tạo Kafka secret 
## 1. Tạo file server.keystore.jks để lưu trữ chứng chỉ SSL
File `server.keystore.jks` được tạo bằng lệnh sau:
```bash
keytool -keystore server.keystore.jks -alias localhost -validity 365 -genkey -keyalg RSA
```
Sau khi chạy lệnh này, bạn sẽ được yêu cầu nhập các thông tin như tên, tổ chức, địa chỉ email, v.v. Hãy chắc chắn rằng bạn nhớ mật khẩu của keystore vì nó sẽ được sử dụng trong các bước tiếp theo.

## 2. Cài đặt quản lý chứng chỉ (Certificate Manager) để quản lý các chứng chỉ SSL
Dùng lệnh sau để tạo CA và Private Key:
```bash
openssl req -new -x509 -keyout ca-key -out ca-cert -days 365 -subj "/CN=Dan Nguyen"
```

## 3. Tạo file CSR (Certificate Signing Request) để yêu cầu cấp chứng chỉ SSL
Dùng lệnh sau để tạo CSR:
```bash
keytool -keystore server.keystore.jks -alias localhost -certreq -file csr-file
```

## 4. Ký kết chứng chỉ SSL
Ký kết chứng chỉ SSL bằng lệnh sau:
```bash
openssl x509 -req -CA ca-cert -CAkey ca-key -in csr-file -out csr-signed -days 365 -CAcreateserial -passin pass:<your_ca_password>
```

Để xem nội dung của CSR, bạn có thể sử dụng lệnh:
```bash
keytool -printcert -v -file cert-signed
```

## 5. Thêm chứng chỉ SSL đã ký vào server.keystore
Sau khi ký kết chứng chỉ, bạn cần thêm nó vào keystore bằng lệnh sau:
```bash
keytool -keystore server.keystore.jks -alias CARoot -import -file ca-cert
keytool -keystore server.keystore.jks -alias localhost -import -file csr-signed
```
## 6. Cấu hình Kafka Broker để sử dụng chứng chỉ SSL

## 7. Tạo file client.truststore.jks ở client để tin cậy chứng chỉ SSL của Kafka Broker
File `client.truststore.jks` được tạo bằng lệnh sau:
```bash
keytool -keystore client.truststore.jks -alias CARoot -import -file ca-cert
```
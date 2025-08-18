# Chạy REDIS CLUSTER
## 1. Chạy trên môi trường Docker container
1. Sửa các file `redis.conf` trong thư mục redis-cluster về giống nhau
``` redis.conf
port 7001 # Port của redis làm master
bind 0.0.0.0
protected-mode no
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
```

2. Sửa file `entrypoint.sh` trong thư mục redis. Các IP sẽ là IP ở bên trong mạng của docker (đã được cấu hình trong file docker-compose.yml)
``` entrypoint.sh
#!/bin/sh

# Using the redis-cli tool available as default in the Redis base image
# we need to create the cluster so they can coordinate with each other
# which key slots they need to hold per shard

# wait a little so we give some time for the Redis containers
# to spin up and be available on the network
sleep 5
# redis-cli doesn't support hostnames, we must match the
# container IP addresses from our docker-compose configuration.
# `--cluster-replicas 1` Will make sure that every master node will have its replica node
echo "yes" | redis-cli --cluster create \
  10.207.248.53:7001 \
  10.207.248.53:7002 \
  10.207.248.53:7003 \
  10.207.248.53:7004 \
  10.207.248.53:7005 \
  10.207.248.53:7006 \
  --cluster-replicas 1
echo "🚀 Redis cluster ready."
```

3. Sửa file `docker-compose.yml` không cần expose port ra ngoài

4. Chạy lệnh `docker-compose up -d` để chạy redis cluster

## 2. Chạy trên môi trường local (Expose port ra ngoài)
1. Sửa các file `redis.conf` trong thư mục redis-cluster theo từng port của từng node
``` cluster_{node}/redis.conf 
port {port} # Port của node
bind 0.0.0.0
protected-mode no
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip 10.207.248.53 # IP của máy host (Tìm trong System32/drivers/etc/hosts có tên là `host.docker.internal`)
appendonly yes
```

2. Sửa file `entrypoint.sh` trong thư mục redis. Các IP sẽ là IP của máy host (Tìm trong System32/drivers/etc/hosts có tên là `host.docker.internal`). Port sẽ là port của từng node
>> Lưu ý: `host.docker.internal` chính là địa chỉ IP của card mạng đang sử dụng. Nên sử dụng IP tĩnh cho card mạng này để tránh trường hợp IP thay đổi khi khởi động lại máy tính.
``` entrypoint.sh
#!/bin/sh

# Using the redis-cli tool available as default in the Redis base image
# we need to create the cluster so they can coordinate with each other
# which key slots they need to hold per shard

# wait a little so we give some time for the Redis containers
# to spin up and be available on the network
sleep 5
# redis-cli doesn't support hostnames, we must match the
# container IP addresses from our docker-compose configuration.
# `--cluster-replicas 1` Will make sure that every master node will have its replica node
echo "yes" | redis-cli --cluster create \
  10.207.248.53:7001 \
  10.207.248.53:7002 \
  10.207.248.53:7003 \
  10.207.248.53:7004 \
  10.207.248.53:7005 \
  10.207.248.53:7006 \
  --cluster-replicas 1
echo "🚀 Redis cluster ready."
```

3. Sửa file `docker-compose.yml` expose port ra ngoài. Mỗi node expose 2 port, 1 port để connect với client, 1 port để connect với các node khác (bus port)

4. Chạy lệnh `docker-compose up -d` để chạy redis cluster

> Luư ý: Port của Redis Cluster phải thêm số `1` vào đầu. Ví dụ. redis port : ["7001:7001"]. Khi dùng cluster cần expose thêm port ["17001:17001"].
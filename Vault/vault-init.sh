#!/bin/sh

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="root"

echo "✅ Vault đã khởi động. Tiến hành cấu hình..."

echo "🔹 Bật Key Value Secrets Engine..."
vault secrets enable -path=kv kv-v2

echo "🔹 Tạo dữ liệu bí mật..."
vault kv put kv/switching-vib viettel-private-key="private-key-content" partner-public-key="public-key-content"
vault kv put kv/switching-bidv viettel-private-key="private-key-content" partner-public-key="public-key-content"
vault kv put kv/switching-vietinbank viettel-private-key="private-key-content" partner-public-key="public-key-content"
vault kv put kv/switching-vpb viettel-private-key="private-key-content" partner-public-key="public-key-content"
vault kv put kv/switching-vba viettel-private-key="private-key-content" partner-public-key="public-key-content"

echo "🔹 Bật AppRole Authentication..."
vault auth enable approle

echo "🔹 Tạo chính sách truy cập..."
vault policy write my-policy - <<EOF
path "kv/data/switching-*" {
  capabilities = ["read"]
}
EOF

echo "🔹 Tạo Role cho AppRole..."
vault write auth/approle/role/my-role secret_id_ttl=10m token_ttl=20m token_max_ttl=30m policies=my-policy

echo "🔹 Lấy Role ID..."
ROLE_ID=$(vault read -field=role_id auth/approle/role/my-role/role-id)
echo "ROLE_ID=$ROLE_ID"

echo "🔹 Lấy Secret ID..."
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/my-role/secret-id)
echo "SECRET_ID=$SECRET_ID"

echo "🔹 Gán Role ID & Secret ID vào biến môi trường cho Spring Boot..."
mkdir -p /vault/secrets/
echo "VAULT_TOKEN=$VAULT_TOKEN" > /vault/secrets/vault-credentials.env
echo "VAULT_ADDR=$VAULT_ADDR" >> /vault/secrets/vault-credentials.env
echo "ROLE_ID=$ROLE_ID" >> /vault/secrets/vault-credentials.env
echo "SECRET_ID=$SECRET_ID" >> /vault/secrets/vault-credentials.env

echo "✅ Vault đã được cấu hình hoàn tất!"

#!/bin/bash

set -o nounset \
    -o errexit \
    -o verbose \
    -o xtrace

# Generate CA key
openssl req -new -x509 -keyout zidane-ca-1.key -out zidane-ca-1.crt -days 365 -subj '/CN=iam.didan.id.vn/OU=IT/O=ZDIDANE/L=PaloAlto/S=Ca/C=US' -passin pass:17052002 -passout pass:17052002
# openssl req -new -x509 -keyout zidane-ca-2.key -out zidane-ca-2.crt -days 365 -subj '/CN=ca2.iam.didan.id.vn/OU=IT/O=ZDIDANE/L=PaloAlto/S=Ca/C=US' -passin pass:17052002 -passout pass:17052002

# Kafkacat
openssl genrsa -des3 -passout "pass:17052002" -out kafkacat.client.key 1024
openssl req -passin "pass:17052002" -passout "pass:17052002" -key kafkacat.client.key -new -out kafkacat.client.req -subj '/CN=kafkacat.iam.didan.id.vn/OU=IT/O=ZDIDANE/L=PaloAlto/S=Ca/C=US'
openssl x509 -req -CA zidane-ca-1.crt -CAkey zidane-ca-1.key -in kafkacat.client.req -out kafkacat-ca1-signed.pem -days 9999 -CAcreateserial -passin "pass:17052002"



for i in kafka1  producer consumer
do
	echo $i
	# Create keystores
	keytool -genkey -noprompt \
				 -alias $i \
				 -dname "CN=$i.iam.didan.id.vn, OU=IT, O=ZDIDANE, L=PaloAlto, S=Ca, C=US" \
				 -keystore kafka.$i.keystore.jks \
				 -keyalg RSA \
				 -storepass 17052002 \
				 -keypass 17052002

	# Create CSR, sign the key and import back into keystore
	keytool -keystore kafka.$i.keystore.jks -alias $i -certreq -file $i.csr -storepass 17052002 -keypass 17052002

	openssl x509 -req -CA zidane-ca-1.crt -CAkey zidane-ca-1.key -in $i.csr -out $i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:17052002

	keytool -keystore kafka.$i.keystore.jks -alias CARoot -import -file zidane-ca-1.crt -storepass 17052002 -keypass 17052002

	keytool -keystore kafka.$i.keystore.jks -alias $i -import -file $i-ca1-signed.crt -storepass 17052002 -keypass 17052002

	# Create truststore and import the CA cert.
	keytool -keystore kafka.$i.truststore.jks -alias CARoot -import -file zidane-ca-1.crt -storepass 17052002 -keypass 17052002

  echo "17052002" > ${i}_sslkey_creds
  echo "17052002" > ${i}_keystore_creds
  echo "17052002" > ${i}_truststore_creds
done
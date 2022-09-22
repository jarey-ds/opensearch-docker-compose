#!/bin/bash
# Generate certificates for your OpenSearch cluster

OPENDISTRO_DN="/C=FR/ST=IDF/L=PARIS/O=EXAMPLE"   # Edit here and in opensearch.yml

mkdir -p certs/{ca,os-dashboards}

# Root CA
openssl genrsa -out certs/ca/ca.key 2048
openssl req -new -x509 -sha256 -days 1095 -subj "$OPENDISTRO_DN/CN=CA" -key certs/ca/ca.key -out certs/ca/ca.pem
cat certs/ca/ca.pem >> certs/ca_bundle.crt

# Admin
openssl genrsa -out certs/ca/admin-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in certs/ca/admin-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out certs/ca/admin.key
openssl req -new -subj "$OPENDISTRO_DN/CN=ADMIN" -key certs/ca/admin.key -out certs/ca/admin.csr
openssl x509 -req -in certs/ca/admin.csr -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out certs/ca/admin.pem
cat certs/ca/admin.pem >> certs/ca_bundle.crt

# OpenSearch Dashboards
openssl genrsa -out certs/os-dashboards/os-dashboards-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in certs/os-dashboards/os-dashboards-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out certs/os-dashboards/os-dashboards.key
openssl req -new -subj "$OPENDISTRO_DN/CN=os-dashboards" -key certs/os-dashboards/os-dashboards.key -out certs/os-dashboards/os-dashboards.csr
openssl x509 -req -in certs/os-dashboards/os-dashboards.csr -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out certs/os-dashboards/os-dashboards.pem
rm certs/os-dashboards/os-dashboards-temp.key certs/os-dashboards/os-dashboards.csr
cat certs/os-dashboards/os-dashboards.pem >> certs/ca_bundle.crt

# Nodes
for NODE_NAME in "os00" "os01" "os02" "os03" "os04" "os05" "os06" "os07"
do
    mkdir "certs/${NODE_NAME}"
    openssl genrsa -out "certs/$NODE_NAME/$NODE_NAME-temp.key" 2048
    openssl pkcs8 -inform PEM -outform PEM -in "certs/$NODE_NAME/$NODE_NAME-temp.key" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "certs/$NODE_NAME/$NODE_NAME.key"
    openssl req -new -subj "$OPENDISTRO_DN/CN=$NODE_NAME" -key "certs/$NODE_NAME/$NODE_NAME.key" -out "certs/$NODE_NAME/$NODE_NAME.csr"
    openssl x509 -req -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1,DNS:$NODE_NAME") -in "certs/$NODE_NAME/$NODE_NAME.csr" -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out "certs/$NODE_NAME/$NODE_NAME.pem"
    cat "certs/$NODE_NAME/$NODE_NAME.pem" >> certs/ca_bundle.crt
    rm "certs/$NODE_NAME/$NODE_NAME-temp.key" "certs/$NODE_NAME/$NODE_NAME.csr"
done

# Build cacerts if java does exist in the path.
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os_ca -file certs/ca/ca.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os_admin -file certs/ca/admin.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os_dash -file certs/os-dashboards/os-dashboards.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os01 -file certs/os01/os01.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os02 -file certs/os02/os02.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os03 -file certs/os03/os03.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os04 -file certs/os03/os04.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os05 -file certs/os03/os05.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os06 -file certs/os03/os06.pem
keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias os07 -file certs/os03/os07.pem
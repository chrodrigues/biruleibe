# Create CA private key

openssl genrsa -out ca.key 4096

# Create CA certificate (valid for 30 years)

openssl req -x509 -new -nodes -key ca.key -sha256 -days 10950 -out ca.crt -subj "/CN=opensearchcluster-name-ca"

Create a Private Key:
openssl genrsa -out cluster.key 4096

Create a Certificate Signing Request (CSR):
First, create a config file (cluster.conf) for SANs:
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = opensearchcluster-name

[v3_req]
keyUsage = critical, digitalSignature
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = opensearchcluster-name
DNS.2 = opensearchcluster-name.homelab-opensearch
DNS.3 = opensearchcluster-name.homelab-opensearch.svc
DNS.4 = opensearchcluster-name.homelab-opensearch.svc.cluster.local
DNS.5 = opensearchcluster-name-master-0
DNS.6 = opensearchcluster-name-master-1
DNS.7 = opensearchcluster-name-master-2
DNS.8 = opensearchcluster-name-data-0
DNS.9 = opensearchcluster-name-data-1
DNS.10 = opensearchcluster-name-coordinators-0

Generate the CSR:
openssl req -new -key cluster.key -out cluster.csr -config cluster.conf

Sign the CSR with the CA:
openssl x509 -req -in cluster.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out cluster.crt -days 9125 -sha256 -extfile
cluster.conf -extensions v3_req

Create Kubernetes Secret:
Generate Base64 Encodings:
base64 -w 0 ca.crt > ca.crt.b64
base64 -w 0 cluster.crt > cluster.crt.b64
base64 -w 0 cluster.key > cluster.key.b64

Create the Secret YAML:

cat <<EOF > cluster-transport-cert.yaml
apiVersion: v1
kind: Secret
metadata:
name: cluster-transport-cert
namespace: homelab-opensearch # Adjust if using 'default'
type: kubernetes.io/tls
data:
ca.crt: $(cat ca.crt.b64)
tls.crt: $(cat cluster.crt.b64)
tls.key: $(cat cluster.key.b64)
EOF
#!/bin/bash

CA_DIRECTORY="/root/ca"
LINE_THIN="---------------------------------------------------------------------"

echo $LINE_THIN
echo 'STEP 1) Creating the CA directory structure and filling in files.'
echo $LINE_THIN

mkdir -p $CA_DIRECTORY/db
mkdir -p $CA_DIRECTORY/newcerts
touch $CA_DIRECTORY/db/index.txt
touch $CA_DIRECTORY/db/index.txt.attr
echo 100000 > $CA_DIRECTORY/db/serial

cat > $CA_DIRECTORY/openssl.cnf << EOF
[ ca ]
default_ca = ca_conf

[ ca_conf ]
dir = $CA_DIRECTORY
private_key = \$dir/ca-root-private-enc.pem
certificate = \$dir/ca-root-certificate.pem
new_certs_dir = \$dir/newcerts

database = \$dir/db/index.txt
serial = \$dir/db/serial

default_md = sha512
policy = policy_strict

[ policy_strict ]
countryName = supplied
stateOrProvinceName = supplied
organizationName = supplied
organizationalUnitName  = supplied
commonName = supplied
emailAddress = optional

[ req ]
distinguished_name = req_distinguished_name
x509_extensions = ca_root
default_md = sha512

[ ca_root ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
nsComment = "LEVEL 1 ROOT CERTIFICATE"


[ ca_intermediate ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
nsComment = "LEVEL 2 INTERMEDIATE CERTIFICATE"

[ ca_user ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "LEVEL 3 CLIENT CERTIFICATE"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ ca_server ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "LEVEL 3 SERVER CERTIFICATE"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ ca_ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
nsComment = "LEVEL 3 OCSP SERVICE CERTIFICATE"

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

countryName_default             = COUNTRY
stateOrProvinceName_default     = PROVINCE
localityName_default            = CITY
0.organizationName_default      = ORGANIZATION
EOF

echo $LINE_THIN
echo 'STEP 2) Creating the CA root key pair. Please enter a password to protect the CA root private key...'
echo $LINE_THIN

openssl ecparam -name secp521r1 -genkey -noout -out $CA_DIRECTORY/ca-root-private.pem
openssl ec -in $CA_DIRECTORY/ca-root-private.pem -out $CA_DIRECTORY/ca-root-private-enc.pem -aes256
rm $CA_DIRECTORY/ca-root-private.pem

echo $LINE_THIN
echo 'STEP 3) Creating the CA public key from the private key. You will need to unlock the root key with the password entered in STEP 2.'
echo $LINE_THIN
openssl ec -in $CA_DIRECTORY/ca-root-private-enc.pem -pubout -out $CA_DIRECTORY/ca-root-public.pem

echo $LINE_THIN
echo 'STEP 4) Creating the CA root certificate.'
echo 'Please unlock the root key using the password entered in STEP 2.'
echo $LINE_THIN
openssl req -config $CA_DIRECTORY/openssl.cnf -key $CA_DIRECTORY/ca-root-private-enc.pem -new -x509 -days 7560 -sha512 -extensions ca_root -out $CA_DIRECTORY/ca-root-certificate.pem

echo $LINE_THIN
echo 'STEP 5) Creating an intermediate key pair. Generating the private key now, please enter a distinct password to protect this key.'
echo $LINE_THIN
openssl ecparam -name secp521r1 -genkey -noout -out $CA_DIRECTORY/ca-int-private.pem
openssl ec -in $CA_DIRECTORY/ca-int-private.pem -out $CA_DIRECTORY/ca-int-private-enc.pem -aes256
rm $CA_DIRECTORY/ca-int-private.pem

echo $LINE_THIN
echo 'STEP 6) Creating the intermediate public key. You will need to unlock the intermediate key with the password entered in STEP 5.'
echo $LINE_THIN
openssl ec -in $CA_DIRECTORY/ca-int-private-enc.pem -pubout -out $CA_DIRECTORY/ca-int-public.pem

echo $LINE_THIN
echo 'STEP 7) Creating a certificate signing request for the intermediate certificate. Please unlock the intermediate key once again, and enter the relevant information for this certificate.'
echo $LINE_THIN
openssl req -config $CA_DIRECTORY/openssl.cnf -key $CA_DIRECTORY/ca-int-private-enc.pem -new -sha512 -extensions ca_intermediate -out $CA_DIRECTORY/ca-int-csr.pem

echo $LINE_THIN
echo 'STEP 8) You will now be asked to sign the intermediate certificate using the root CA.'
echo "Please unlock the root key using the password provided in STEP 2 to proceed."
echo $LINE_THIN
openssl ca -config $CA_DIRECTORY/openssl.cnf -extensions ca_intermediate -days 3600 -notext -md sha512 -in $CA_DIRECTORY/ca-int-csr.pem -out $CA_DIRECTORY/ca-int-certificate.pem

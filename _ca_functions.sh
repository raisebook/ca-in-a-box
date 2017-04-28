#!/bin/bash

set -eo pipefail

export PATH=${PATH}:/usr/local/bin

: "${CA_BUCKET:?"Need set the S3 Bucket where we store the CA Data"}"
: "${CA_KMS_KEY:?"Need set the KMS Key Name to encrypt the CA Data"}"

function get_ca_password {
  read -s -r -p "Enter the Server CA Password: " CA_PASS
}

function load_s3_data {
  aws s3 sync --acl private --sse aws:kms --sse-kms-key-id "${CA_KMS_KEY}" "s3://${CA_BUCKET}/" "${DIR}/"
}

function save_s3_data {
  read -p "Commit changes to shared storage? (Y/N) " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    aws s3 sync --acl private --sse aws:kms --sse-kms-key-id "${CA_KMS_KEY}" "${DIR}/" "s3://${CA_BUCKET}/"
    echo ""
    echo "CA Updated!"
  fi
}

function generate_initial_configs {
  if [ ! -f ${DIR}/openssl.conf ]; then
    mkdir certs crl newcerts private
    chmod 700 private
    touch index.txt
    echo 1000 > serial

    mkdir -p intermediate/certs intermediate/crl intermediate/csr intermediate/newcerts intermediate/private
    chmod 700 intermediate/private
    touch intermediate/index.txt
    echo 1000 > intermediate/serial
    echo 1000 > intermediate/crlnumber

    templater.sh /root/openssl.conf.tmpl -f /root/cfg/config.txt > openssl.conf
    templater.sh /root/openssl-intermediate.conf.tmpl -f /root/cfg/config.txt > intermediate/openssl.conf
  fi
}

function create_root_cert {
  if [ ! -f ${DIR}/private/ca.key.pem ]; then
    echo "[ROOT] Generate Key"
    openssl genrsa -passout pass:${CA_PASS} -aes256 -out private/ca.key.pem 4096
    chmod 400 private/ca.key.pem

    echo "[ROOT] Generate Root Certificate"
    openssl req -config openssl.conf \
      -key private/ca.key.pem \
      -passin pass:${CA_PASS} \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem

    chmod 444 certs/ca.cert.pem
    echo "[ROOT] Verify Certificate"
    openssl x509 -noout -text -in certs/ca.cert.pem
  fi
}

function create_intermediate_cert {
  if [ ! -f ${DIR}/intermediate/private/intermediate.key.pem ]; then
    echo "[Intermediate] Generate Key"
    openssl genrsa -aes256 \
            -passout pass:${CA_PASS} \
            -out intermediate/private/intermediate.key.pem 4096
    chmod 400 intermediate/private/intermediate.key.pem

    echo "[Intermediate] Generate CSR"
    openssl req -config intermediate/openssl.conf -new -sha256 \
      -passin pass:${CA_PASS} -passout pass:${CA_PASS} \
      -key intermediate/private/intermediate.key.pem \
      -out intermediate/csr/intermediate.csr.pem

    echo "[Intermediate] Generate Certificate"
    openssl ca -config /root/ca/openssl.conf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -passin pass:${CA_PASS} \
      -in intermediate/csr/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem

    chmod 444 intermediate/certs/intermediate.cert.pem

    echo "[Intermediate] Verify Certificate"
    openssl x509 -noout -text -in intermediate/certs/intermediate.cert.pem
    openssl verify -CAfile certs/ca.cert.pem  intermediate/certs/intermediate.cert.pem

    echo "[Intermediate] Generate Chain File"
    cat intermediate/certs/intermediate.cert.pem certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
    chmod 444 intermediate/certs/ca-chain.cert.pem

  fi
}

function create_server_cert {
  echo "[Server] Generate Key"
  read -r -p "Enter the Server Common Name:" SERVER_CN

  if [ -f ${DIR}/${SERVER_CN}/server.key.pem ]; then
    echo "A certificate for ${SERVER_CN} already exists."
    exit -1
  else
    mkdir /root/ca/${SERVER_CN}
    openssl genrsa -out ${SERVER_CN}/server.key.pem 2048
    chmod 400 ${SERVER_CN}/server.key.pem

    echo "[Server] Generate CSR"
    SERVER_CN=${SERVER_CN} templater.sh /root/openssl-intermediate.conf.tmpl \
                 -f <(cat /root/cfg/config.txt | sed "s/^CN_INTERMEDIATE.*$/CN_INTERMEDIATE=${SERVER_CN}/") \
                 > ${SERVER_CN}/openssl.conf
    
    openssl req -config ${SERVER_CN}/openssl.conf \
                -key ${SERVER_CN}/server.key.pem \
                -new -sha256 -out ${SERVER_CN}/server.csr.pem

    echo "[Server] Generate Certificate"
    openssl ca -config ${SERVER_CN}/openssl.conf \
        -extensions server_cert -days 3650 -notext -md sha256 \
        -passin pass:${CA_PASS} \
        -in ${SERVER_CN}/server.csr.pem \
        -out ${SERVER_CN}/server.cert.pem
    chmod 444 ${SERVER_CN}/server.cert.pem

    echo "[Server] Verify Certificate"
    openssl x509 -noout -text -in ${SERVER_CN}/server.cert.pem
    openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
        ${SERVER_CN}/server.cert.pem
  fi
}

function export_server_cert {
  if [ -f ${DIR}/${SERVER_CN}/server.key.pem ]; then
    cp ${SERVER_CN}/server.cert.pem /root/output/${SERVER_CN}.cert.pem
    cp ${SERVER_CN}/server.key.pem /root/output/${SERVER_CN}.key.pem
    cp intermediate/certs/ca-chain.cert.pem /root/output/ca-chain.cert.pem
  fi
}

function export_root_cert {
  if [ -f ${DIR}/certs/ca.cert.pem ]; then
    cp ${DIR}/certs/ca.cert.pem /root/output/root-ca.cert.pem
    cp intermediate/certs/ca-chain.cert.pem /root/output/ca-chain.cert.pem
  fi
}

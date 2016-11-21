#!/bin/bash

set -eo pipefail

export PATH=${PATH}:/usr/local/bin

DIR=/root/ca
cd /root/ca

templater.sh openssl.conf.tmpl -f /root/cfg/config.txt > openssl.conf
templater.sh openssl-intermediate.conf.tmpl -f /root/cfg/config.txt > intermediate/openssl.conf

function create_root_cert {
  if [ ! -f ${DIR}/private/ca.key.pem ]; then
    echo "[ROOT] Generate Key"
    openssl genrsa -aes256 -out private/ca.key.pem 4096
    chmod 400 private/ca.key.pem

    echo "[ROOT] Generate Root Certificate"
    openssl req -config openssl.conf \
      -key private/ca.key.pem \
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
    openssl genrsa -aes256 -out intermediate/private/intermediate.key.pem 4096
    chmod 400 intermediate/private/intermediate.key.pem

    echo "[Intermediate] Generate CSR"
    openssl req -config intermediate/openssl.conf -new -sha256 \
      -key intermediate/private/intermediate.key.pem \
      -out intermediate/csr/intermediate.csr.pem

    echo "[Intermediate] Generate Certificate"
    openssl ca -config /root/ca/openssl.conf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
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

create_root_cert
create_intermediate_cert


#!/bin/bash

set -eo pipefail

export PATH=${PATH}:/usr/local/bin

source /usr/local/bin/_ca_functions.sh

DIR=/root/ca
cd /root/ca

load_s3_data
export_root_cert

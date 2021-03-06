#!/bin/bash

set -eo pipefail

export PATH=${PATH}:/usr/local/bin

source /usr/local/bin/_ca_functions.sh

DIR=/root/ca
cd /root/ca

get_ca_password
load_s3_data
generate_initial_configs

create_root_cert
create_intermediate_cert
create_server_cert
export_server_cert

save_s3_data

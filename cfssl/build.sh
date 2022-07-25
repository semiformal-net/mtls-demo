#!/bin/bash

#
# Adapted from https://gist.github.com/moolen/d940dd909dbc633a1413ef0715386f99
#

set -euo pipefail
readonly SERVER_HOST_NAME="localhost"
readonly CA_ROOT_CERT_KEY="ca-root"
readonly CA_INTERMEDIATE_CERT_KEY="ca-intermediate"
readonly SERVER_CERT_KEY="localhost"
readonly CLIENT_CERT_KEY="localhost.client"
readonly COMBINED_CA="combined.ca.pem"

mkdir certs
touch certs/$COMBINED_CA

# Generate the Root certificate
cfssl genkey \
    -initca \
    config/ca.json | cfssljson -bare certs/${CA_ROOT_CERT_KEY}

# Generate the intermediate certificate
cfssl gencert \
    -initca \
    config/ca.json | cfssljson -bare certs/${CA_INTERMEDIATE_CERT_KEY}

# Sign intermediate certificate with root certificate
cfssl sign \
    -ca certs/${CA_ROOT_CERT_KEY}.pem \
    -ca-key certs/${CA_ROOT_CERT_KEY}-key.pem \
    -config config/ca-root-to-intermediate-config.json \
    certs/${CA_INTERMEDIATE_CERT_KEY}.csr \
| cfssljson -bare certs/${CA_INTERMEDIATE_CERT_KEY}

## Server certificate
cfssl gencert \
	-ca certs/${CA_INTERMEDIATE_CERT_KEY}.pem \
	-ca-key certs/${CA_INTERMEDIATE_CERT_KEY}-key.pem \
	-config config/ca-config.json \
	-profile server \
	-hostname "${SERVER_HOST_NAME}" \
	- \
	<<-CONFIG | cfssljson -bare certs/${SERVER_CERT_KEY}
{
	"CN": "${SERVER_HOST_NAME}",
	"key": {
		"algo": "rsa",
		"size": 4096
	},
	"hosts": ["127.0.0.1","localhost"]
}
CONFIG

## Client certificate
cfssl gencert \
	-ca certs/${CA_INTERMEDIATE_CERT_KEY}.pem \
	-ca-key certs/${CA_INTERMEDIATE_CERT_KEY}-key.pem \
	-config config/ca-config.json \
	-profile client \
	-hostname "MY_CLIENT" \
	- \
	<<-CONFIG | cfssljson -bare certs/${CLIENT_CERT_KEY}
{
	"CN": "CLIENT_NAME",
	"key": {
		"algo": "rsa",
		"size": 4096
	}
}
CONFIG

# Concatenate the root and intermediate certificates
cat certs/${CA_INTERMEDIATE_CERT_KEY}.pem >> certs/$COMBINED_CA
cat certs/${CA_ROOT_CERT_KEY}.pem >> certs/$COMBINED_CA

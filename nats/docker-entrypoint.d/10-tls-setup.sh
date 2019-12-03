#!/usr/bin/env bash

if [ -z "${CN}" ]; then
  CN=$(hostname)
fi
CA_SERVER=${CA_SERVER:-puppetca.local}
CERTFILE="/etc/nats/ssl/certs/${CN}.pem"

CA_API_URL=https://${CA_SERVER}:8140/puppet-ca/v1/certificate/ca
CRL_API_URL=https://${CA_SERVER}:8140/puppet-ca/v1/certificate_revocation_list/ca

# Request certificate if not already available
if [ ! -f ${CERTFILE} ]; then
  # Wait for CA API to be available
  while ! curl -k -s -f $CA_API_URL > /dev/null; do
    echo "---> Waiting for CA API at ${CA_SERVER}..."
    sleep 10
  done

  echo "---> Requesting certificate for ${CN} from ${CA_SERVER}"
  # TODO investigate why the permissions are wrong
  # -> should be set correctly in Dockerfile
  # -> maybe gets overwriten because of volume mount
  # -> but in Puppetserver it works
  chown -R nats /etc/nats
  su -s /bin/sh nats -c "/usr/bin/ruby \
    /usr/local/bin/request-cert.rb \
    --caserver ${CA_SERVER} \
    --cn ${CN} \
    --ssldir /etc/nats/ssl"

  if [ ! -f ${CERTFILE} ]; then
    echo "---> Certificate retrieval failed. Exiting"
    exit 1
  fi
fi


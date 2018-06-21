#!/bin/sh
set -e
set -u

DUMB_INIT=$(which dumb-init)
ENVCONSUL=$(which envconsul)

if [[ -z "$CONSUL_HTTP_ADDR" ]]; then
  consul_ip_aws=$(curl -f -s http://169.254.169.254/latest/meta-data/local-ipv4)
  CONSUL_IP=${consul_ip_aws:-127.0.0.1}
  CONSUL_HTTP_ADDR="http://${CONSUL_IP}:8500"
  export CONSUL_HTTP_ADDR
fi

$DUMB_INIT \
  $ENVCONSUL \
  $EXTRA_ARGS \
  -prefix "$CONSUL_PREFIX" \
  -upcase \
  -sanitize \
  -exec=./app

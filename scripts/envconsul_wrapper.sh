#!/bin/sh
set -e
set -u

DUDEWHERESMY=$(PATH=$PATH:. which dudewheresmy)
DUMB_INIT=$(which dumb-init)
ENVCONSUL=$(which envconsul)

if [[ -z "$CONSUL_HTTP_ADDR" ]]; then
  CONSUL_IP=$($DUDEWHERESMY hostip)
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

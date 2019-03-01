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

if [[ -z "$VAULT_ADDR" ]]; then
  VAULT_IP=$($DUDEWHERESMY hostip)
  VAULT_ADDR="http://${VAULT_IP}:8200"
  export VAULT_ADDR
fi

_HCL_CONFIG=$(cat<<EOT
secret {
  no_prefix = true
  path      = "${VAULT_PATH}"
}
EOT
)
echo "${_HCL_CONFIG}" > config.hcl

if [ -z "$VAULT_TOKEN" ]; then
  $DUMB_INIT \
    $ENVCONSUL \
    $EXTRA_ARGS \
    -prefix "$CONSUL_PREFIX" \
    -upcase \
    -sanitize \
    -exec=./app
else
    $DUMB_INIT \
      $ENVCONSUL \
      $EXTRA_ARGS \
      -prefix "$CONSUL_PREFIX" \
      -upcase \
      -sanitize \
      -config config.hcl \
      -exec=./app
fi

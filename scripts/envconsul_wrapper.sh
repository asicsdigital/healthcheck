#!/bin/sh
set -e
set -u

DUDEWHERESMY=$(PATH=$PATH:. which dudewheresmy)
DUMB_INIT=$(which dumb-init)
ENVCONSUL=$(which envconsul)
VAULT_ROLE="${VAULT_ROLE:-hc}"

if [[ -z "$CONSUL_HTTP_ADDR" ]]; then
  CONSUL_IP=$($DUDEWHERESMY hostip)
  CONSUL_HTTP_ADDR="http://${CONSUL_IP}:8500"
  export CONSUL_HTTP_ADDR
fi

if [[ -z "$VAULT_ADDR" ]]; then
  CONSUL_IP=$($DUDEWHERESMY hostip)
  VAULT_IP=$(dig +short active.vault.service.consul @${CONSUL_IP} -p 8600)
  VAULT_PORT=$(dig -t srv +short active.vault.service.consul @${CONSUL_IP} -p 8600 | cut -d' ' -f3)
  VAULT_ADDR="http://${VAULT_IP}:${VAULT_PORT}"
  export VAULT_ADDR
fi

if curl -fs -m 1 http://169.254.169.254/latest/meta-data/ -o /dev/null ; then
  echo "Logging into Vault with role: ${VAULT_ROLE}"
  vault login -no-print=true -method=aws role=${VAULT_ROLE}

  if [ -f .vault-token ]; then
       VAULT_TOKEN=$(cat .vault-token)
       export VAULT_TOKEN
  fi
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
#  CONSUL_IP=$(./dudewheresmy ip) ; VAULT_IP=$(dig +short active.vault.service.consul @${CONSUL_IP} -p 8600); VAULT_PORT=$(dig -t srv +short active.vault.service.consul @${CONSUL_IP} -p 8600 | cut -d' ' -f3) ; VAULT_ADDR="http://${VAULT_IP}:${VAULT_PORT}"

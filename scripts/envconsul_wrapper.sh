#!/bin/sh
set -e
set -u

DUMB_INIT=$(which dumb-init)
ENVCONSUL=$(which envconsul)

$DUMB_INIT \
  $ENVCONSUL \
  $EXTRA_ARGS \
  -prefix "$CONSUL_PREFIX" \
  -upcase \
  -sanitize \
  -exec=./app

#!/bin/sh

BACKEND=${BACKEND:="base"}
SCRIPT_DIR=$(dirname $0)
"${SCRIPT_DIR}/${BACKEND}-network-init.sh"

#!/bin/sh

URL="${1}"

if [ -z "${URL}" ]; then
  echo "Usage: $0 <url> [provisioners]" >&2
  exit 1
fi

BASE_URL=`dirname ${URL}`
IMAGE=`basename ${URL} | sed 's;\.img$;;'`

echo "BASE_URL = ${BASE_URL}" >Makefile
echo "IMAGE = ${IMAGE}" >>Makefile
echo "TYPE = bhyve" >>Makefile
shift
reggae init ${@}

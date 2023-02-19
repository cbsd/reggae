#!/bin/sh

TEMPFILE=$(mktemp)

reggae init ${@}
echo "TYPE = bhyve" >"${TEMPFILE}"
cat Makefile >>"${TEMPFILE}"
mv "${TEMPFILE}" Makefile

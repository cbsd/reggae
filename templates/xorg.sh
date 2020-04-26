#!/bin/sh

X_ENABLED="XORG"
DOMAIN=`reggae get-config DOMAIN`

if [ "${X_ENABLED}" = "YES" ]; then
  xhost +"${jname}.${DOMAIN}" >/dev/null 2>&1
fi

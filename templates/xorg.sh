#!/bin/sh


X_ENABLED="XORG"
DOMAIN=`reggae get-config DOMAIN`

if [ "${X_ENABLED}" = "YES" ]; then
  xhost +"${jname}.${DOMAIN}"
fi

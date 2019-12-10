#!/bin/sh

echo "GID=${GID} UID=${UID}"

pw group add devel -g ${GID}
pw user add devel -u ${UID} -g devel -s /bin/tcsh -G wheel -m
mkdir -p /home/devel/.ssh
chmod 700 /home/devel/.ssh
chpass -p '$6$61V0w0dRFFiEcnm2$o8CLPIdRBVHP13LQizdp12NEGD91RfHSB.c6uKnr9m2m3ZCg7ASeGENMaDt0tffmo5RalKGjWiHCtScCtjYfs/' devel

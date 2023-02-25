#!/bin/sh

pw group add provision -g 666
pw user add provision -u 666 -g provision -s /bin/tcsh -G wheel -m
sysrc ifconfig_vtnet0="SYNCDHCP"
service cloudinit disable
service nfsclient enable
mkdir -p /home/provision/.ssh
chmod 700 /home/provision/.ssh
chpass -p '$6$61V0w0dRFFiEcnm2$o8CLPIdRBVHP13LQizdp12NEGD91RfHSB.c6uKnr9m2m3ZCg7ASeGENMaDt0tffmo5RalKGjWiHCtScCtjYfs/' provision

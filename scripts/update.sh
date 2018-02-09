#!/bin/sh


if [ -e /usr/sbin/hbsd-update ]; then
  /usr/sbin/hbsd-update
else
  /usr/sbin/freebsd-update fetch
  /usr/sbin/freebsd-update install
fi

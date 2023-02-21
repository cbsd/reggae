#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=$(dirname $0)
. "${SCRIPT_DIR}/default.conf"

setup_base() {
  if [ ! -d /var/log/jails ]; then
    mkdir /var/log/jails
  fi
  touch /etc/jail.conf
  echo "reggae_enable=\"YES\"" >/etc/rc.conf.d/reggae
  service reggae start
  echo "jail_enable=\"YES\"" >/etc/rc.conf.d/jail
  echo "jail_list=\"\"" >>/etc/rc.conf.d/jail
}


setup_base

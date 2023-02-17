#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

setup_base() {
  HOST=$(hostname)
  sed "s/HOST/${HOST}/g" "${SCRIPT_DIR}/../templates/base-jail.conf" >/etc/jail.conf
  echo "reggae_enable=\"YES\"" >/etc/rc.conf.d/reggae
  service reggae start
  echo "jail_enable=\"YES\"" >/etc/rc.conf.d/jail
  echo "jail_list=\"\"" >>/etc/rc.conf.d/jail
}


setup_base

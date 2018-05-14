#!/bin/sh

MODE=${1:-"prod"}
CONF_DIR="/usr/local/etc/salt/master.d"

pkg install -y py36-salt
echo 'salt_master_enable="YES"' >/etc/rc.conf.d/salt_master
if [ ! -e "${CONF_DIR}" ]; then
  mkdir "${CONF_DIR}"
fi

if [ "${MODE}" = "devel" ]; then
  echo "open_mode: True" >"${CONF_DIR}/open.conf"
else
  rm "${CONF_DIR}/open.conf"
fi
service salt_master restart

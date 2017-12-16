#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

. "/usr/local/share/reggae/scripts/default.conf"
EGRESS=`netstat -rn | awk '/^default/{print $4}'`
EGRESS_CONFIG=`sysrc -n ifconfig_${EGRESS}`
DHCP_CONFIG=`echo ${EGRESS_CONFIG} | grep -io dhcp`
STATIC=NO

if [ -z "${DHCP_CONFIG}" ]; then
    STATIC=YES
fi

if [ "${STATIC}" = "YES" ]; then
    if [ ! -e /tmp/resolv.conf ]; then
        cp /etc/resolv.conf /tmp
    fi
else
    if [ -e /tmp/resolv.conf ]; then
        resolvconf -d "${EGRESS}"
    fi
    resolvconf -u
fi

SEARCH=`awk /^search/{print $2} /tmp/resolv.conf`
echo "search ${SEARCH}" >/etc/resolv.conf
echo nameserver ${RESOLVER_IP} >>/etc/resolv.conf
/etc/dhclient-exit-hooks


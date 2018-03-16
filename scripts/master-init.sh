#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
    . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"

HOSTNAME=`hostname`
EGRESS=`netstat -rn | awk '/^default/{print $4}'`
EGRESS_CONFIG=`sysrc -n ifconfig_${EGRESS}`
DHCP_CONFIG=`echo ${EGRESS_CONFIG} | grep -io dhcp`
NODEIP=`ifconfig ${EGRESS} | awk '/inet /{print $2}'`
TEMP_INITENV_CONF=`mktemp`
TEMP_RESOLVER_CONF=`mktemp`
TEMP_DHCP_CONF=`mktemp`
STATIC=NO


if [ -z "${DHCP_CONFIG}" ]; then
    STATIC=YES
fi


resolver() {
    sed \
      -e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
      -e "s:DOMAIN:${DOMAIN}:g" \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      ${SCRIPT_DIR}/../templates/resolver.conf >"${TEMP_RESOLVER_CONF}"

    cbsd jcreate inter=0 jconf="${TEMP_RESOLVER_CONF}"
    echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/resolver-data/etc/rc.conf.d/sendmail"
    echo 'named_enable="YES"' >"${CBSD_WORKDIR}/jails-data/resolver-data/etc/rc.conf.d/named"
    cbsd jstart resolver
    cp "${SCRIPT_DIR}/../templates/dhclient-exit-hooks" /etc
    chmod 700 /etc/dhclient-exit-hooks
    if [ ! -f "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key" ]; then
        cbsd jexec jname=resolver rndc-confgen -a -c /usr/local/etc/namedb/cbsd.key -k cbsd
        chown bind:bind "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key"
    fi
    RNDC_KEY=`awk -F '"' '/secret/{print $2}' "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key"`
    sed \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      "${SCRIPT_DIR}/../templates/named.conf" \
      >"${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/named.conf"
    sed \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      "${SCRIPT_DIR}/../templates/my.domain" \
      >"${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/my.domain"
    sed \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      "${SCRIPT_DIR}/../templates/vm.my.domain" \
      >"${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/vm.my.domain"

    chown bind:bind \
      "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/my.domain"
      "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/vm.my.domain"

    if [ "${STATIC}" = "NO" ]; then
      sed \
        -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
        "${SCRIPT_DIR}/../templates/resolvconf.conf" >/etc/resolvconf.conf
    fi

    /etc/dhclient-exit-hooks nohup
    cbsd jexec jname=resolver service named restart
    sed \
      -e "s:HOSTNAME:${HOSTNAME}:g" \
      -e "s:NODEIP:${NODEIP}:g" \
      -e "s:RESOLVERS:${RESOLVER_IP}:g" \
      -e "s:NATIP:${NATIP}:g" \
      -e "s:JAIL_IP_POOL:${JAIL_IP_POOL}:g" \
      -e "s:ZFSFEAT:${ZFSFEAT}:g" \
      ${SCRIPT_DIR}/../templates/initenv.conf >"${TEMP_INITENV_CONF}"
    cbsd initenv inter=0 "${TEMP_INITENV_CONF}"
}


dhcp() {
    sed \
      -e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
      -e "s:DOMAIN:${DOMAIN}:g" \
      -e "s:DHCP_IP:${DHCP_IP}:g" \
      ${SCRIPT_DIR}/../templates/dhcp.conf >"${TEMP_DHCP_CONF}"

    cbsd jcreate inter=0 jconf="${TEMP_DHCP_CONF}"
    cp \
      "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key" \
      "${CBSD_WORKDIR}/jails-data/dhcp-data/usr/local/etc/"
    DHCP_BASE=`echo ${DHCP_IP} | awk -F '.' '{print $1 "." $2 "." $3}'`
    DHCP_SUBNET="${DHCP_BASE}.0/24"
    DHCP_SUBNET_FIRST="${DHCP_BASE}.1"
    DHCP_SUBNET_LAST="${DHCP_BASE}.200"
    sed \
      -e "s:DOMAIN:${DOMAIN}:g" \
      -e "s:VM_INTERFACE_IP:${VM_INTERFACE_IP}:g" \
      -e "s:VM_INTERFACE:${VM_INTERFACE}:g" \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      -e "s:DHCP_IP:${DHCP_IP}:g" \
      -e "s:DHCP_SUBNET_FIRST:${DHCP_SUBNET_FIRST}:g" \
      -e "s:DHCP_SUBNET_LAST:${DHCP_SUBNET_LAST}:g" \
      -e "s:DHCP_SUBNET:${DHCP_SUBNET}:g" \
      -e "s:RNDC_KEY:${RNDC_KEY}:g" \
      ${SCRIPT_DIR}/../templates/kea.conf >"${CBSD_WORKDIR}/jails-data/dhcp-data/usr/local/etc/kea/kea.conf"
    cp ${SCRIPT_DIR}/../templates/keactrl.conf "${CBSD_WORKDIR}/jails-data/dhcp-data/usr/local/etc/kea/"
    echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/sendmail"
    echo 'kea_enable="YES"' >"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/kea"
    echo 'service kea start' >"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.local"
    cbsd jstart dhcp
}


resolver
dhcp

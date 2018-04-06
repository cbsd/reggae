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

    ZONE_BASE=`hostname`

    cbsd jcreate inter=0 jconf="${TEMP_RESOLVER_CONF}"
    echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/resolver-data/etc/rc.conf.d/sendmail"
    echo 'named_enable="YES"' >"${CBSD_WORKDIR}/jails-data/resolver-data/etc/rc.conf.d/named"
    sed \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      "${SCRIPT_DIR}/../templates/rndc.conf" \
      >"${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/rndc.conf"
    cbsd jstart resolver
    cp "${SCRIPT_DIR}/../templates/dhclient-exit-hooks" /etc
    chmod 700 /etc/dhclient-exit-hooks
    if [ ! -f "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key" ]; then
        cbsd jexec jname=resolver rndc-confgen -a -c /usr/local/etc/namedb/cbsd.key -k cbsd
        chown bind:bind "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key"
    fi
    RNDC_KEY=`awk -F '"' '/secret/{print $2}' "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/cbsd.key"`
    REVERSE_ZONE=`echo ${DHCP_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
    RESOLVER_IP_LAST=`echo ${RESOLVER_IP} | awk -F '.' '{print $4}'`
    sed \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      -e "s:ZONE_BASE:${ZONE_BASE}:g" \
      -e "s:REVERSE_ZONE:${REVERSE_ZONE}:g" \
      "${SCRIPT_DIR}/../templates/named.conf" \
      >"${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/named.conf"
    sed \
      -e "s:RESOLVER_IP_LAST:${RESOLVER_IP_LAST}:g" \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      -e "s:ZONE_BASE:${ZONE_BASE}:g" \
      -e "s:REVERSE_ZONE:${REVERSE_ZONE}:g" \
      "${SCRIPT_DIR}/../templates/my.domain.rev" \
      >"${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}.rev"
    sed \
      -e "s:RESOLVER_IP_LAST:${RESOLVER_IP_LAST}:g" \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      -e "s:ZONE_BASE:${ZONE_BASE}:g" \
      "${SCRIPT_DIR}/../templates/my.domain" \
      >"${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}"

    echo "Changing permissions"
    chown bind:bind \
      "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}" \
      "${CBSD_WORKDIR}/jails-data/resolver-data/usr/local/etc/namedb/dynamic/${ZONE_BASE}.rev"
    echo "Permissions changed"

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
    cp ${SCRIPT_DIR}/../templates/dhcpd-hook.sh "${CBSD_WORKDIR}/jails-data/dhcp-data/usr/local/bin/"
    chmod 755 "${CBSD_WORKDIR}/jails-data/dhcp-data/usr/local/bin/dhcpd-hook.sh"
    DHCP_BASE=`echo ${DHCP_IP} | awk -F '.' '{print $1 "." $2 "." $3}'`
    REVERSE_ZONE=`echo ${DHCP_IP} | awk -F '.' '{print $3 "." $2 "." $1 ".in-addr.arpa"}'`
    DHCP_SUBNET_FIRST="${DHCP_BASE}.1"
    DHCP_SUBNET_LAST="${DHCP_BASE}.200"
    sed \
      -e "s:DOMAIN:${DOMAIN}:g" \
      -e "s:VM_INTERFACE_IP:${VM_INTERFACE_IP}:g" \
      -e "s:RESOLVER_IP:${RESOLVER_IP}:g" \
      -e "s:REVERSE_ZONE:${REVERSE_ZONE}:g" \
      -e "s:DHCP_SUBNET_FIRST:${DHCP_SUBNET_FIRST}:g" \
      -e "s:DHCP_SUBNET_LAST:${DHCP_SUBNET_LAST}:g" \
      -e "s:DHCP_BASE:${DHCP_BASE}:g" \
      ${SCRIPT_DIR}/../templates/dhcpd.conf >"${CBSD_WORKDIR}/jails-data/dhcp-data/usr/local/etc/dhcpd.conf"
    echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/sendmail"
    echo 'dhcpd_enable="YES"' >"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_flags="-q"' >>"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/dhcpd"
    echo "dhcpd_ifaces=\"${VM_INTERFACE}\"" >>"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_conf="/usr/local/etc/dhcpd.conf"' >>"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/dhcpd"
    echo 'dhcpd_withumask="022"' >>"${CBSD_WORKDIR}/jails-data/dhcp-data/etc/rc.conf.d/dhcpd"

    cbsd jstart dhcp
}


resolver
dhcp

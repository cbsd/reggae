CBSD_WORKDIR="/cbsd"
DOMAIN="my.domain"
SSHD_FLAGS=`sysrc -n sshd_flags`
SHORT_HOSTNAME=`hostname -s`
HOSTNAME=`hostname`
RESOLVER=`grep '^nameserver' /etc/resolv.conf | head -n 1 | awk '{print $2}'`
CLONED_INTERFACES=`sysrc -n cloned_interfaces`
NATIP=`netstat -rn | awk '/^default/{print $2}'`
EGRESS=`netstat -rn | awk '/^default/{print $4}'`
NODEIP=`ifconfig ${EGRESS} | awk '/inet /{print $2}'`
TEMP_INITENV_CONF=`mktemp`

rm -rf /tmp/ifaces.txt
touch /tmp/ifaces.txt
for iface in ${CLONED_INTERFACES}; do
    echo "${iface}" >>/tmp/ifaces.txt
done


LO1_INTERFACE=`grep '^lo1$' /tmp/ifaces.txt`
if [ -z "${LO1_INTERFACE}" ]; then
    if [ -z "${CLONED_INTERFACES}" ]; then
        CLONED_INTERFACES="lo1"
    else
        CLONED_INTERFACES="${CLONED_INTERFACES} lo1"
    fi
    sysrc ifconfig_lo1="up"
fi

BRIDGE1_INTERFACE=`grep '^bridge1$' /tmp/ifaces.txt`
if [ -z "${BRIDGE1_INTERFACE}" ]; then
    CLONED_INTERFACES="${CLONED_INTERFACES} bridge1"
    sysrc ifconfig_bridge1="inet 172.16.0.1 netmask 255.255.255.0 description ${EGRESS}"
fi

sysrc cloned_interfaces="${CLONED_INTERFACES}"
service netif cloneup
rm -rf /tmp/ifaces.txt


if [ ! -d "${CBSD_WORKDIR}" ]; then
    zfs create -o mountpoint=${CBSD_WORKDIR} zroot${CBSD_WORKDIR}
fi

if [ "${HOSTNAME}" == "${SHORT_HOSTNAME}" ]; then
    HOSTNAME="${SHORT_HOSTNAME}.${DOMAIN}"
    hostname ${HOSTNAME}
    sysrc hostname="${HOSTNAME}"
fi

if [ -z "${SSHD_FLAGS}" ]; then
    sysrc sshd_flags=""
fi

sed \
  -e "s:HOSTNAME:${HOSTNAME}:g" \
  -e "s:NODEIP:${NODEIP}:g" \
  -e "s:NAMESERVER:${RESOLVER}:g" \
  -e "s:NATIP:${NATIP}:g" \
  /usr/local/share/reggae/templates/initenv.conf >"${TEMP_INITENV_CONF}"

env workdir="${CBSD_WORKDIR}" /usr/local/cbsd/sudoexec/initenv "${TEMP_INITENV_CONF}"
rm -rf "${TEMP_INITENV_CONF}"
service cbsdd start
service cbsdrsyncd start
echo 1 | cbsd jcreate jconf="/usr/local/share/reggae/templates/consul.conf"
cat <<EOF >"${CBSD_WORKDIR}/jails-data/consul-data/etc/rc.conf.d/consul"
consul_enable="YES"
consul_args="-node=${SHORT_HOSTNAME} -bind=127.0.2.1 -client=127.0.2.1 -recursor=${RESOLVER} -ui -bootstrap -server"
EOF
mkdir "${CBSD_WORKDIR}/jails-data/consul-data/usr/local/etc/consul.d"
echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/consul-data/etc/rc.conf.d/sendmail"
cbsd jstart consul

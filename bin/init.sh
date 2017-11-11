PROJECT_BIN_PATH=`dirname "${0}"`
PROJECT_ROOT=`readlink -f "${PROJECT_BIN_PATH}/.."`
CBSD_WORKDIR="/cbsd"
DOMAIN="my.domain"
SSHD_FLAGS=`sysrc -n sshd_flags`
SHORT_HOSTNAME=`hostname -s`
HOSTNAME=`hostname`
RESOLVER=`grep '^nameserver' /etc/resolv.conf | head -n 1 | awk '{print $2}'`


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

env workdir="${CBSD_WORKDIR}" /usr/local/cbsd/sudoexec/initenv "${PROJECT_ROOT}/templates/initenv.conf"
service cbsdd start
service cbsdrsyncd start
echo 1 | cbsd jcreate jconf="${PROJECT_ROOT}/templates/consul.conf"
cat <<EOF >"${CBSD_WORKDIR}/jails-data/consul-data/etc/rc.conf.d/consul"
consul_enable="YES"
consul_args="-node=${SHORT_HOSTNAME} -bind=127.0.2.1 -client=127.0.2.1 -recursor=${RESOLVER} -ui -bootstrap -server"
EOF
mkdir "${CBSD_WORKDIR}/jails-data/consul-data/usr/local/etc/consul.d"
echo 'sendmail_enable="NONE"' >"${CBSD_WORKDIR}/jails-data/consul-data/etc/rc.conf.d/sendmail"
cbsd jstart consul

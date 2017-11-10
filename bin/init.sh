PROJECT_BIN_PATH=`dirname "${0}"`
PROJECT_ROOT=`dirname "${PROJECT_BIN_PATH}"`
CBSD_WORKDIR="/cbsd"
SSHD_FLAGS=`sysrc sshd_flags | cut -f 2- -d ':' | awk '{print $1}'`
HOSTNAME="thinker.meka.no-ip.org"
SET_HOSTNAME=""


if [ ! -d "${CBSD_WORKDIR}" ]; then
    zfs create -o mountpoint=${CBSD_WORKDIR} zroot${CBSD_WORKDIR}
fi

if [ `hostname` == `hostname -s` ]; then
    SET_HOSTNAME="yes"
    hostname ${HOSTNAME}
    sysrc hostname="${HOSTNAME}"
fi

if [ -z "${SSHD_FLAGS}" ]; then
    sysrc sshd_flags=""
fi

echo ${INIT_COMMAND}
${INIT_COMMAND}
env workdir="${CBSD_WORKDIR}" /usr/local/cbsd/sudoexec/initenv "${PROJECT_ROOT}/templates/initenv.conf"

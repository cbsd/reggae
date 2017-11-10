CONF_FILE="/usr/local/etc/reggae.conf"
if [ -f "${CONF_FILE}" ]; then
    . "${CONF_FILE}"
fi

TEMP_FILE=`mktemp`
JAIL_NAME=${jname}
JAIL_IP=`echo ${ip4_addr} | cut -f 1 -d '/'`
ACTION="${1}"
CONSUL=${CONSUL:-"http://127.0.2.1:8500"}
TEMPLATE=${TEMPLATE:-"${PROJECT_ROOT}/templates/register.tpl"}

sed \
    -e "s/JAIL_NAME/${JAIL_NAME}/g" \
    -e "s/JAIL_IP/${JAIL_IP}/g" \
    ${TEMPLATE} \
    >${TEMP_FILE}

/usr/local/bin/curl -s -X PUT "${CONSUL}/v1/catalog/${ACTION}" -d @${TEMP_FILE} >/dev/null >&2
rm -rf ${TEMP_FILE}


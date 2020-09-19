#!/bin/sh

TEMP_FILE=`mktemp`

passwd_file=$1
shift
prompt_string=$1
shift
passwd=`cat ${passwd_file}`

echo "#!/usr/local/bin/expect -f" >"${TEMP_FILE}"
echo "spawn $@" >>"${TEMP_FILE}"
echo "expect ${prompt_string}" >>"${TEMP_FILE}"
echo "send -- \"${passwd}\\r\"" >>"${TEMP_FILE}"
echo "expect eof" >>"${TEMP_FILE}"
chmod +x "${TEMP_FILE}"
"${TEMP_FILE}"

rm -rf "${TEMP_FILE}"

#!/bin/sh


DIRECTORY=$1
if [ -z "${DIRECTORY}" ]; then
  echo "Usage: reggae pf <directory>" >&2
  exit 1
fi

cd "${DIRECTORY}"
for anchor_file in `find . -type f`; do
  anchor=`echo ${anchor_file} | cut -b 3-`
  pfctl -a ${anchor} -f ${anchor_file}
done

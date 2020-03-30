#!/bin/sh

if [ -f "/usr/local/etc/reggae.conf" ]; then
  . "/usr/local/etc/reggae.conf"
fi

SCRIPT_DIR=`dirname $0`
. "${SCRIPT_DIR}/default.conf"


PROJECT_ROOT=`readlink -f ${SCRIPT_DIR}/..`
MAKEFILE="Makefile.service"
PROVISIONERS=$@
SERVICE_NAME=`basename ${PWD}`
case ${SERVICE_NAME} in
  jail*)
    SERVICE_NAME=`echo ${SERVICE_NAME} | cut -b 5-`
    ;;
esac
case ${SERVICE_NAME} in
  -*)
    SERVICE_NAME=`echo ${SERVICE_NAME} | cut -b 2-`
    ;;
esac

echo -n "Generating Makefile ... "
sed -e "s;SERVICE_NAME;${SERVICE_NAME};g" "${PROJECT_ROOT}/templates/${MAKEFILE}" >Makefile
echo "done"

echo -n "Generating .gitignore ... "
cp "${PROJECT_ROOT}/templates/gitignore" .gitignore
echo "done"

echo -n "Generating tests ..."
mkdir bin
echo "#!/bin/sh" >bin/test.sh
chmod +x bin/test.sh
echo "done"

rm -rf provisioners.mk
for provisioner in ${PROVISIONERS}; do
  echo ".include <\${REGGAE_PATH}/mk/${provisioner}.mk>" >>provisioners.mk
  if [ -d "${PROJECT_ROOT}"/skel/${provisioner} ]; then
    echo -n "Populating from skel for ${provisioner} ... "
    cp -r "${PROJECT_ROOT}"/skel/${provisioner}/* .
    echo "done"
  fi
done

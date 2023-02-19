#!/bin/sh


BACKEND=$(reggae get-config BACKEND)
PKG_PROXY=$(reggae get-config PKG_PROXY)

if [ "${BACKEND}" = "base" ]; then
  BASE_WORKDIR=$(reggae get-config BASE_WORKDIR)
  for jail_version in $(ls -1d "${BASE_WORKDIR}"/*/bin/freebsd-version); do
    jname=$(echo "${jail_version}" | sed "s;${BASE_WORKDIR}/;;g" | cut -f 1 -d '/')
    pkg_file="${BASE_WORKDIR}/${jname}/usr/local/etc/pkg.conf"
    sed -i "" -r "/^pkg_env.*/d" "${pkg_file}"
    if [ "${PKG_PROXY}" != "no" ]; then
      echo "pkg_env : { http_proxy: \"http://${PKG_PROXY}/\" }" >>"${pkg_file}"
    fi
  done
elif [ "${BACKEND}" = "cbsd" ]; then
  CBSD_WORKDIR=$(sysrc -s cbsdd -n cbsd_workdir)
  for jname in $(env NOCOLOR=1 cbsd jls header=0 display=jname); do
    pkg_file="${CBSD_WORKDIR}/jails-data/${jname}-data/usr/local/etc/pkg.conf"
    sed -i "" -r "/^pkg_env.*/d" "${pkg_file}"
    if [ "${PKG_PROXY}" != "no" ]; then
      echo "pkg_env : { http_proxy: \"http://${PKG_PROXY}/\" }" >>"${pkg_file}"
    fi
  done
fi

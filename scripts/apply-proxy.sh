#!/bin/sh


CBSD_WORKDIR=`sysrc -s cbsdd -n cbsd_workdir`
PKG_PROXY=`reggae get-config PKG_PROXY`

for jname in $(env NOCOLOR=1 cbsd jls header=0 display=jname); do
  pkg_file="${CBSD_WORKDIR}/jails-data/${jname}-data/usr/local/etc/pkg.conf"
  sed -i "" -r "/^pkg_env.*/d" "${pkg_file}"
  if [ "${PKG_PROXY}" != "no" ]; then
    echo "pkg_env : { http_proxy: \"http://${PKG_PROXY}/\" }" >>"${pkg_file}"
  fi
done

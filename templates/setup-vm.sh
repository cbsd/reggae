#!/bin/sh

trap "rm -rf ${0}" HUP INT ABRT BUS TERM  EXIT

mdo sysrc hostname=SERVICE.DOMAIN
mdo hostname SERVICE.DOMAIN
mdo pw group add devel -g GID
mdo pw user add devel -w none -m -s /bin/tcsh -u UID -G wheel
mdo cp -rp ~provision/.ssh ~devel/
mdo chown -R devel:devel ~devel/

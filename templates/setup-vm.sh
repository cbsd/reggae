#!/bin/sh

trap "rm -rf ${0}" HUP INT ABRT BUS TERM  EXIT

sudo sysrc hostname=SERVICE.DOMAIN
sudo hostname SERVICE.DOMAIN
sudo pw group add devel -g GID
sudo pw user add devel -w none -m -s /bin/tcsh -u UID -G wheel
sudo cp -rp ~provision/.ssh ~devel/
sudo chown -R devel:devel ~devel/

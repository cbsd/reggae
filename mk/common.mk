TYPE ?= jail
VERSION ?= native
EXTRA_FSTAB ?= templates/fstab
XORG ?= NO
DEVEL_MODE ?= NO
RUNNING_UID != id -u
RUNNING_GID != id -g
UID ?= ${RUNNING_UID}
GID ?= ${RUNNING_GID}
DOMAIN != reggae get-config DOMAIN
CBSD_WORKDIR != sysrc -s cbsdd -n cbsd_workdir
EXTRA_PACKAGES =

.for provisioner in ${PROVISIONERS}
.if ${provisioner} == "ansible"
EXTRA_PACKAGES += python
.endif
.endfor

.if exists(vars.mk)
.include <vars.mk>
.endif

DEVEL_MODE ?= NO
RUNNING_UID := `id -u`
RUNNING_GID := `id -g`
UID ?= ${RUNNING_UID}
GID ?= ${RUNNING_GID}
DOMAIN = `reggae get-config DOMAIN`
CBSD_WORKDIR != sysrc -n cbsd_workdir
TYPE ?= jail
EXTRA_PACKAGES =

.for provisioner in ${PROVISIONERS}
.if ${provisioner} == "ansible"
EXTRA_PACKAGES += python36
.endif
.endfor

.MAIN: up

.include <${REGGAE_PATH}/mk/${TYPE}-service.mk>

.if exists(vars.mk)
.include <vars.mk>
.endif

DEVEL_MODE ?= "NO"
UID ?= 1001
GID ?= 1001
DOMAIN ?= my.domain
CBSD_WORKDIR!=sysrc -n cbsd_workdir

.MAIN: up

up: setup
	@sudo cbsd jcreate jconf=${PWD}/cbsd.conf || true
.if defined(EXTRA_FSTAB)
	@sudo cp ${EXTRA_FSTAB} ${CBSD_WORKDIR}/jails-fstab/fstab.${SERVICE}.local
.endif
.if ${DEVEL_MODE} == "YES"
	@sudo sh -c "echo ${PWD} /usr/src nullfs rw 0 0 >>${CBSD_WORKDIR}/jails-fstab/fstab.${SERVICE}.local"
.endif
.if !exists(${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/register.sh)
	@sudo cp /usr/local/share/reggae/templates/register.sh ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/register.sh
	@sudo chmod 755 ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/register.sh
.endif
.if !exists(${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststop.d/deregister.sh)
	@sudo cp /usr/local/share/reggae/templates/deregister.sh ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststop.d/deregister.sh
	@sudo chmod 755 ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststop.d/deregister.sh
.endif
	@sudo cbsd jstart ${SERVICE} || true
	@sudo chown ${UID}:${GID} cbsd.conf
.if ${DEVEL_MODE} == "YES"
.if !exists(${CBSD_WORKDIR}/jails/${SERVICE}/usr/home/devel)
	@sudo cbsd jexec jname=${SERVICE} pw group add devel -g ${GID}
	@sudo cbsd jexec jname=${SERVICE} pw user add devel -u ${UID} -g devel -s /bin/tcsh -G wheel,operator -m
	@sudo cbsd jexec jname=${SERVICE} chpass -p '$6$MIv4IXAika7jqFH2$GkYSBax0G9CIBG0DcgQMP5gG7Qt.CojExDcU7YOQy0K.pouAd.edvo/MaQPhVO0fISxjOD4J1nzRsGVXUAxGp1' devel
.endif
.endif
.if !exists(.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif

provision:
	@touch .provisioned
.if target(do-provision)
	@${MAKE} ${MAKEFLAGS} do-provision
.endif

down: setup
	@sudo cbsd jstop ${SERVICE} || true

destroy: down
	@rm -f cbsd.conf .provisioned
	@sudo cbsd jremove ${SERVICE}
.if target(do-clean)
	@${MAKE} ${MAKEFLAGS} do-clean
.endif

setup:
	@sed -e "s:SERVICE:${SERVICE}:g" -e "s:DOMAIN:${DOMAIN}:g" ${REGGAE_PATH}/templates/cbsd.conf.tpl >cbsd.conf
.if target(do-setup)
	@${MAKE} ${MAKEFLAGS} do-setup
.endif

login:
	@sudo cbsd jlogin ${SERVICE}

exec:
	@sudo cbsd jexec jname=${SERVICE} ${command}

export: down
.if !exists(build)
	@mkdir build
.endif
	@echo -n "Exporting jail ... "
	@sudo cbsd jexport jname=${SERVICE}
	@sudo mv ${CBSD_WORKDIR}/export/${SERVICE}.img build/
	@sudo chown ${UID}:${GID} build/${SERVICE}.img

devel:
	@sudo jexec -U devel ${SERVICE} /usr/src/bin/init.sh
	@sudo jexec -U devel ${SERVICE} /usr/src/bin/devel.sh

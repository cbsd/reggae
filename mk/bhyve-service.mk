DATA_DIR = ${CBSD_WORKDIR}/jails-data/${SERVICE}-data

up: ${DATA_DIR}
.if ${DEVEL_MODE} == "YES"
	@sudo cbsd bset jname=${SERVICE} astart=0
.else
	@sudo cbsd bset jname=${SERVICE} astart=1
.endif
	@sudo cbsd bstart jname=${SERVICE} || true
.if !exists(.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif

provision: ${DATA_DIR}
	@touch .provisioned

down: ${DATA_DIR}
	@sudo cbsd bstop ${SERVICE} || true

destroy:
	@rm -f .provisioned
	@sudo cbsd bremove ${SERVICE}
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} clean-${provisioner}
.endfor

${DATA_DIR}:
	@sudo cbsd bclone old=basehardenedbsd11 new=${SERVICE}
	@sudo cbsd bstart ${SERVICE}
	@echo "Waiting for VM to get up"
	@sleep 15
	@sudo reggae bhyve-set-hostname ${SERVICE} ${DOMAIN}
	@sudo cbsd bstop ${SERVICE}

login:
	@ssh provision@${SERVICE}.${DOMAIN}

exec:
	@ssh provision@${SERVICE}.${DOMAIN} ${command}

export: down
.if !exists(build)
	@mkdir build
.endif
	@sudo cbsd bexport jname=${SERVICE}
	@echo "Moving ${SERVICE}.img to build dir ..."
	@sudo mv ${CBSD_WORKDIR}/export/${SERVICE}.img build/
	@echo "Chowning ${SERVICE}.img to ${UID}:${GID} ..."
	@sudo chown ${UID}:${GID} build/${SERVICE}.img

devel: up
	@ssh devel@${SERVICE}.${DOMAIN} /usr/src/bin/devel.sh

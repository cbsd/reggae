DATA_DIR = ${CBSD_WORKDIR}/jails-data/${SERVICE}-data
BASE_DATA_DIR = ${CBSD_WORKDIR}/jails-data/${IMAGE}-data
PWD != pwd
VM_INTERFACE_IP != reggae get-config VM_INTERFACE_IP

.if target(pre_up)
up: ${DATA_DIR} pre_up
.else
up: ${DATA_DIR}
.endif
	@sudo cbsd bstart jname=${SERVICE} || true
	@echo "Waiting for VM to boot"
	@sudo reggae ssh-ping ${SERVICE}
	@sudo reggae scp provision ${SERVICE} ${REGGAE_PATH}/templates/install-packages.sh ${UID} ${GID}
	@sudo reggae ssh provision ${SERVICE} chmod +x ./install-packages.sh
	@sudo reggae ssh provision ${SERVICE} ./install-packages.sh ${EXTRA_PACKAGES}
	@sudo reggae scp provision ${SERVICE} ${REGGAE_PATH}/templates/mount-project.sh ${UID} ${GID}
	@sudo reggae ssh provision ${SERVICE} chmod +x ./mount-project.sh
	@sudo reggae ssh provision ${SERVICE} ./mount-project.sh ${PWD}
.if !exists(.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif
.if target(post_up)
	@${MAKE} ${MAKEFLAGS} post_up
.endif

provision: ${DATA_DIR}
	@touch .provisioned
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} provision-${provisioner}
.endfor

down: ${DATA_DIR}
	@sudo cbsd bstop ${SERVICE} || true

destroy:
	@rm -f .provisioned
	@sudo cbsd bremove ${SERVICE}
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} clean-${provisioner}
.endfor

${DATA_DIR}: ${BASE_DATA_DIR}
	@sudo cbsd bclone old=${IMAGE} new=${SERVICE}
	@sudo cbsd bset jname=${SERVICE} astart=0
	@sudo cbsd bstart jname=${SERVICE}
	@echo "Waiting for VM to boot"
	@sudo reggae ssh-ping ${SERVICE}
	@sudo reggae scp provision ${SERVICE} ${REGGAE_PATH}/templates/setup-vm.sh ${UID} ${GID}
	@sudo reggae ssh provision ${SERVICE} chmod +x ./setup-vm.sh
	@sudo reggae ssh provision ${SERVICE} ./setup-vm.sh
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} setup-${provisioner}
.endfor

${BASE_DATA_DIR}:
	@rm -rf /tmp/${IMAGE}.img
	@fetch ${BASE_URL}/${IMAGE}.img -o /tmp/${IMAGE}.img
	@sudo reggae import /tmp/${IMAGE}.img bhyve
	@rm -rf /tmp/${IMAGE}.img

login:
.if defined(user)
	@sudo reggae ssh ${user} ${SERVICE}
.else
	@sudo reggae ssh provision ${SERVICE}
.endif

exec:
	@sudo reggae ssh provision ${SERVICE} ${command}

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
	@sudo reggae ssh devel ${SERVICE} /usr/src/bin/devel.sh

test: up
	@sudo reggae ssh devel ${SERVICE} /usr/src/bin/test.sh

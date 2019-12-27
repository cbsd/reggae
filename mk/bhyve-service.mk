DATA_DIR = ${CBSD_WORKDIR}/jails-data/${SERVICE}-data
INTERFACE != reggae get-config INTERFACE
INTERFACE_IP != reggae get-config INTERFACE_IP
MASTER_IP != reggae get-config MASTER_IP
PROJECTS_DIR != reggae get-config PROJECTS_DIR
CPU ?= 1
MEM ?= "1G"

.if target(pre_up)
up: ${DATA_DIR} pre_up
.else
up: ${DATA_DIR}
.endif
	@sudo cbsd bset jname=${SERVICE} vm_cpus=${CPU} vm_ram=${MEM}
	@sudo cbsd bstart jname=${SERVICE} || true
	@echo "Waiting for VM to boot"
	@sudo reggae ssh-ping ${SERVICE}
.if !exists(${CBSD_WORKDIR}/jails-system/${SERVICE}/.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif
.if target(post_up)
	@${MAKE} ${MAKEFLAGS} post_up
.endif

provision:
	-@sudo touch ${CBSD_WORKDIR}/jails-system/${SERVICE}/.provisioned
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} provision-${provisioner}
.endfor

down:
	@sudo cbsd bstop ${SERVICE} || true

destroy:
	@rm -f .provisioned
	@sudo cbsd bremove ${SERVICE}
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} clean-${provisioner}
.endfor

${DATA_DIR}:
	@sed \
		-e "s:SERVICE:${SERVICE}:g" \
		-e "s:DOMAIN:${DOMAIN}:g" \
		-e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
		-e "s:MASTER_IP:${MASTER_IP}:g" \
		-e "s:INTERFACE_IP:${INTERFACE_IP}:g" \
		-e "s:INTERFACE:${INTERFACE}:g" \
		${REGGAE_PATH}/templates/cbsd-bhyve.conf.tpl >cbsd.conf
	@sudo cbsd bcreate jconf=${PWD}/cbsd.conf
	@sudo cp ${REGGAE_PATH}/templates/cloud-init/user-data ${CBSD_WORKDIR}/jails-system/${SERVICE}/cloud-init
	@sed \
		-e "s:SERVICE:${SERVICE}:g" \
		-e "s:DOMAIN:${DOMAIN}:g" \
		${REGGAE_PATH}/templates/cloud-init/meta-data >/tmp/${SERVICE}-meta-data
	@sudo mv /tmp/${SERVICE}-meta-data ${CBSD_WORKDIR}/jails-system/${SERVICE}/cloud-init/meta-data
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} setup-${provisioner}
.endfor
.if target(post_setup)
	@${MAKE} ${MAKEFLAGS} post_setup
.endif
	@sudo cbsd bstart jname=${SERVICE}
	@${MAKE} ${MAKEFLAGS} init ip=`sudo cbsd bget jname=${SERVICE} ip4_addr | cut -f 2 -d ':' | cut -b 2-`
	@sudo cbsd bstop ${SERVICE}

init:
	@echo "Waiting for VM to boot for the first time"
	@sudo env IP=${ip} SSH_USER=cbsd reggae ssh-ping ${SERVICE}
	@sudo env IP=${ip} reggae scp cbsd ${SERVICE} ${REGGAE_PATH}/templates/cloud-initial.sh
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} chmod +x cloud-initial.sh
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo ./cloud-initial.sh
	@sudo env IP=${ip} reggae scp cbsd ${SERVICE} ${REGGAE_PATH}/id_rsa.pub
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo mv /home/cbsd/id_rsa.pub /home/provision/.ssh/authorized_keys
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo chmod 600 /home/provision/.ssh/authorized_keys
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo chown -R provision:provision /home/provision
	@sudo env IP=${ip} reggae scp cbsd ${SERVICE} ${REGGAE_PATH}/templates/sudoers
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo chown root:wheel sudoers
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo mv sudoers /usr/local/etc/
.if defined(EXTRA_SCRIPT)
	@sudo env IP=${ip} reggae scp cbsd ${SERVICE} ${EXTRA_SCRIPT}
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo chown root:wheel `basename ${EXTRA_SCRIPT}`
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo chmod +x `basename ${EXTRA_SCRIPT}`
	@sudo env IP=${ip} reggae ssh cbsd ${SERVICE} sudo mv /home/cbsd/`basename ${EXTRA_SCRIPT}` /usr/local/bin/
.endif
	@sudo env IP=${ip} reggae scp provision ${SERVICE} ${REGGAE_PATH}/templates/cloud-devops.sh
	@sudo env IP=${ip} reggae scp provision ${SERVICE} ${REGGAE_PATH}/id_rsa.pub
	@sudo env IP=${ip} reggae ssh provision ${SERVICE} sudo pw user del cbsd -r

login:
.if defined(user)
	@sudo env VERBOSE="yes" reggae ssh ${user} ${SERVICE}
.else
	@sudo env VERBOSE="yes" reggae ssh provision ${SERVICE}
.endif

exec:
	@sudo env VERBOSE="yes" reggae ssh provision ${SERVICE} ${command}

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
.if ${DEVEL_MODE} == "YES"
	@sudo reggae ssh provision ${SERVICE} sudo env UID=${UID} GID=${GID} sh cloud-devops.sh ${INTERFACE_IP} ${PWD} /usr/src ${EXTRA_SCRIPT}
	@sudo env VERBOSE="yes" reggae ssh devel ${SERVICE} /usr/src/bin/devel.sh
.else
	@echo "DEVEL_MODE is not enabled" >&2
	@false
.endif

test: up
	@sudo env VERBOSE="yes" reggae ssh devel ${SERVICE} /usr/src/bin/test.sh

upgrade: up
	@sudo env VERBOSE="yes" reggae ssh provision ${SERVICE} pkg upgrade -y

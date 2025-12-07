DATA_DIR = ${CBSD_WORKDIR}/jails-data/${SERVICE}-data
INTERFACE != reggae get-config INTERFACE
INTERFACE_IP != reggae get-config INTERFACE_IP
MASTER_IP != reggae get-config MASTER_IP
PROJECTS_DIR != reggae get-config PROJECTS_DIR
OS ?= "freebsd"
DISTRIBUTION ?= ""
VERSION ?= "native"
CPU ?= 1
MEM ?= "1G"

.if ${VERSION} == "native"
VERSION != freebsd-version | sed -e 's/-RELEASE.*//'
.endif

.if target(pre_up)
up: ${DATA_DIR} pre_up
.else
up: ${DATA_DIR}
.endif
	@mdo cbsd bset jname=${SERVICE} vm_cpus=${CPU} vm_ram=${MEM}
	@mdo cbsd bstart jname=${SERVICE} || true
	@echo "Waiting for VM to boot"
	@mdo reggae ssh-ping ${SERVICE}
.if !exists(${CBSD_WORKDIR}/jails-system/${SERVICE}/.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif
.if target(post_up)
	@${MAKE} ${MAKEFLAGS} post_up
.endif

provision:
	-@mdo touch ${CBSD_WORKDIR}/jails-system/${SERVICE}/.provisioned
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} provision-${provisioner}
.endfor

down:
	@mdo cbsd bstop ${SERVICE} || true

destroy:
	@rm -f .provisioned
	@mdo cbsd bremove ${SERVICE}
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
		-e "s:OS:${OS}:g" \
		-e "s:DISTRIBUTION:${DISTRIBUTION}:g" \
		-e "s:VERSION:${VERSION}:g" \
		${REGGAE_PATH}/templates/cbsd-bhyve.${OS}.conf.tpl >cbsd.conf
	@mdo cbsd bcreate jconf=${PWD}/cbsd.conf
	@mdo cp ${REGGAE_PATH}/templates/cloud-init/user-data ${CBSD_WORKDIR}/jails-system/${SERVICE}/cloud-init
	@sed \
		-e "s:SERVICE:${SERVICE}:g" \
		-e "s:DOMAIN:${DOMAIN}:g" \
		${REGGAE_PATH}/templates/cloud-init/meta-data >/tmp/${SERVICE}-meta-data
	@mdo mv /tmp/${SERVICE}-meta-data ${CBSD_WORKDIR}/jails-system/${SERVICE}/cloud-init/meta-data
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} setup-${provisioner}
.endfor
	@mdo cbsd bstart jname=${SERVICE}
	@${MAKE} ${MAKEFLAGS} init ip=`mdo cbsd bget jname=${SERVICE} ip4_addr | cut -f 2 -d ':' | cut -b 2-`
	@mdo cbsd bstop ${SERVICE}

init:
	@echo "Waiting for VM to boot for the first time"
	@mdo env IP=${ip} SSH_USER=cbsd reggae ssh-ping ${SERVICE}
	@mdo env IP=${ip} reggae scp cbsd ${SERVICE} ${REGGAE_PATH}/templates/cloud-initial.sh
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} chmod +x cloud-initial.sh
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo ./cloud-initial.sh
	@mdo env IP=${ip} reggae scp cbsd ${SERVICE} ${REGGAE_PATH}/id_rsa.pub
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo mv /home/cbsd/id_rsa.pub /home/provision/.ssh/authorized_keys
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo chmod 600 /home/provision/.ssh/authorized_keys
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo chown -R provision:provision /home/provision
	@mdo env IP=${ip} reggae scp cbsd ${SERVICE} ${REGGAE_PATH}/templates/mdoers
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo chown root:wheel mdoers
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo mv mdoers /usr/local/etc/
.if defined(EXTRA_SCRIPT)
	@mdo env IP=${ip} reggae scp cbsd ${SERVICE} ${EXTRA_SCRIPT}
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo chown root:wheel `basename ${EXTRA_SCRIPT}`
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo chmod +x `basename ${EXTRA_SCRIPT}`
	@mdo env IP=${ip} reggae ssh cbsd ${SERVICE} mdo mv /home/cbsd/`basename ${EXTRA_SCRIPT}` /usr/local/bin/
.endif
	@mdo env IP=${ip} reggae scp provision ${SERVICE} ${REGGAE_PATH}/templates/cloud-devops.sh
	@mdo env IP=${ip} reggae scp provision ${SERVICE} ${REGGAE_PATH}/id_rsa.pub
.if target(post_setup)
	@@${MAKE} ${MAKEFLAGS} post_setup ip=${ip}
.endif
	@mdo env IP=${ip} reggae ssh provision ${SERVICE} mdo pw user del cbsd -r

login:
.if defined(user)
	@mdo env VERBOSE="yes" reggae ssh ${user} ${SERVICE}
.else
	@mdo env VERBOSE="yes" reggae ssh provision ${SERVICE}
.endif

exec:
	@mdo env VERBOSE="yes" reggae ssh provision ${SERVICE} ${command}

export: down
.if !exists(build)
	@mkdir build
.endif
	@mdo cbsd bexport jname=${SERVICE}
	@echo "Moving ${SERVICE}.img to build dir ..."
	@mdo mv ${CBSD_WORKDIR}/export/${SERVICE}.img build/
	@echo "Chowning ${SERVICE}.img to ${UID}:${GID} ..."
	@mdo chown ${UID}:${GID} build/${SERVICE}.img

.if target(do_devel)
devel: up do_devel
.else
devel: up
.if ${DEVEL_MODE} == "YES"
	@mdo reggae ssh provision ${SERVICE} mdo env UID=${UID} GID=${GID} sh cloud-devops.sh ${INTERFACE_IP} ${PWD} /usr/src ${EXTRA_SCRIPT}
	@mdo env VERBOSE="yes" reggae ssh devel ${SERVICE} /usr/src/bin/devel.sh
.else
	@echo "DEVEL_MODE is not enabled" >&2
	@false
.endif
.endif

test: up
	@mdo env VERBOSE="yes" reggae ssh devel ${SERVICE} /usr/src/bin/test.sh

upgrade: up
	@mdo env VERBOSE="yes" reggae ssh provision ${SERVICE} pkg upgrade -y

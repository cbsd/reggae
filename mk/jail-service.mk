up: setup
	@sudo cbsd jcreate jconf=${PWD}/cbsd.conf || true
.if defined(EXTRA_FSTAB)
	@sudo cp ${EXTRA_FSTAB} ${CBSD_WORKDIR}/jails-fstab/fstab.${SERVICE}.local
.else
	@sudo rm -rf ${CBSD_WORKDIR}/jails-fstab/fstab.${SERVICE}.local
.endif
.if ${DEVEL_MODE} == "YES"
	@sudo sh -c "echo ${PWD} /usr/src nullfs rw 0 0 >>${CBSD_WORKDIR}/jails-fstab/fstab.${SERVICE}.local"
	@sudo cbsd jset jname=${SERVICE} astart=0
.else
	@sudo cbsd jset jname=${SERVICE} astart=1
.endif
.if !exists(${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/provision/.ssh/authorized_keys)
.if !exists(${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/provision/.ssh)
	-@sudo mkdir ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/provision/.ssh
.endif
	@sudo chmod 700 ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/provision/.ssh
	@sudo cp ~/.ssh/id_rsa.pub ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/provision/.ssh/authorized_keys
	@sudo chmod 600 ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/provision/.ssh/authorized_keys
	@sudo chown -R 666:666 ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/provision/.ssh
.endif
	@sudo sed -i -e 's:quarterly:latest:g' ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/etc/pkg/FreeBSD.conf >/dev/null 2>&1 || true
	@sudo cbsd jstart ${SERVICE} || true
	@sudo chown ${UID}:${GID} cbsd.conf
.if ${DEVEL_MODE} == "YES"
.if !exists(${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/home/devel)
	@sudo cbsd jexec jname=${SERVICE} pw groupadd devel -g ${GID}
	@sudo cbsd jexec jname=${SERVICE} pw useradd devel -u ${UID} -g devel -s /bin/tcsh -G wheel,operator -m
	@sudo cbsd jexec jname=${SERVICE} chpass -p '$6$MIv4IXAika7jqFH2$GkYSBax0G9CIBG0DcgQMP5gG7Qt.CojExDcU7YOQy0K.pouAd.edvo/MaQPhVO0fISxjOD4J1nzRsGVXUAxGp1' devel
.endif
.else
	@echo 'Deleting user "devel"'
	-@sudo cbsd jexec jname=${SERVICE} pw user del devel -r >/dev/null 2>&1
	@echo 'User "devel" deleted'
.endif
	@sudo cbsd jexec jname=${SERVICE} pwd_mkdb /etc/master.passwd
.if !exists(.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif

provision: setup
	@touch .provisioned
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} provision-${provisioner}
.endfor

down: setup
	@sudo cbsd jstop ${SERVICE} || true

destroy:
	@rm -f cbsd.conf .provisioned
	@sudo cbsd jremove ${SERVICE}
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} clean-${provisioner}
.endfor

setup:
	@sed \
		-e "s:SERVICE:${SERVICE}:g" \
		-e "s:DOMAIN:${DOMAIN}:g" \
		-e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
		-e "s:EXTRA_PACKAGES:${EXTRA_PACKAGES}:g" \
		${REGGAE_PATH}/templates/cbsd.conf.tpl >cbsd.conf
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} setup-${provisioner}
.endfor

login:
.if defined(user)
	@sudo cbsd jlogin user=${user} ${SERVICE}
.else
	@sudo cbsd jlogin ${SERVICE}
.endif

exec:
	@sudo cbsd jexec jname=${SERVICE} ${command}

export: down
.if !exists(build)
	@mkdir build
.endif
	@sudo cbsd jexport jname=${SERVICE}
	@echo "Moving ${SERVICE}.img to build dir ..."
	@sudo mv ${CBSD_WORKDIR}/export/${SERVICE}.img build/
	@echo "Chowning ${SERVICE}.img to ${UID}:${GID} ..."
	@sudo chown ${UID}:${GID} build/${SERVICE}.img

devel: up
	@sudo cbsd jexec jname=${SERVICE} user=devel cmd=/usr/src/bin/devel.sh

test: up
	@sudo jexec -U devel ${SERVICE} /usr/src/bin/test.sh

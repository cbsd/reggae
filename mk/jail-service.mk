SUBTYPE ?= vnet
INTERFACE != reggae get-config INTERFACE
PKG_MIRROR_CONFIG != reggae get-config PKG_MIRROR
PKG_REPO_CONFIG != reggae get-config PKG_REPO
PKG_MIRROR ?= ${PKG_MIRROR_CONFIG}
PKG_REPO ?= ${PKG_REPO_CONFIG}


.if target(pre_up)
up: setup pre_up
.else
up: setup
.endif
	@sudo cbsd jstart ${SERVICE} || true
	@sudo chown ${UID}:${GID} cbsd.conf
.if !exists(${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/sbin/pkg)
	@sudo cbsd jexec jname=${SERVICE} env ASSUME_ALWAYS_YES=YES pkg bootstrap
	@sudo cbsd jexec jname=${SERVICE} pkg install -y sudo ${EXTRA_PACKAGES}
.endif
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
.if !exists(${CBSD_WORKDIR}/jails-system/${SERVICE}/.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif
.if target(post_up)
	@${MAKE} ${MAKEFLAGS} post_up
.endif

provision: setup
	-@sudo touch ${CBSD_WORKDIR}/jails-system/${SERVICE}/.provisioned
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

.if target(pre_setup)
setup: pre_setup
.else
setup:
.endif
.if $(SUBTYPE) == "vnet"
	@sed \
		-e "s:SERVICE:${SERVICE}:g" \
		-e "s:DOMAIN:${DOMAIN}:g" \
		-e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
		-e "s:EXTRA_PACKAGES:${EXTRA_PACKAGES}:g" \
		-e "s:INTERFACE:${INTERFACE}:g" \
		-e "s:VERSION:${VERSION}:g" \
		${REGGAE_PATH}/templates/cbsd-vnet.conf.tpl >cbsd.conf
.else
	@sed \
		-e "s:SERVICE:${SERVICE}:g" \
		-e "s:DOMAIN:${DOMAIN}:g" \
		-e "s:CBSD_WORKDIR:${CBSD_WORKDIR}:g" \
		-e "s:EXTRA_PACKAGES:${EXTRA_PACKAGES}:g" \
		-e "s:INTERFACE:${INTERFACE}:g" \
		-e "s:DEVFS_RULESET:${DEVFS_RULESET}:g" \
		-e "s:VERSION:${VERSION}:g" \
		${REGGAE_PATH}/templates/cbsd.conf.tpl >cbsd.conf
.endif
.for provisioner in ${PROVISIONERS}
	@${MAKE} ${MAKEFLAGS} setup-${provisioner}
.endfor
.if target(post_setup)
	@${MAKE} ${MAKEFLAGS} post_setup
.endif
	@sudo cbsd jcreate jconf=${PWD}/cbsd.conf || true
.if exists(${EXTRA_FSTAB})
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
	@sudo cp ${REGGAE_PATH}/templates/export-ports.sh ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d
	@sudo sed -i "" \
		-e "s:PRTS:${PORTS}:g" \
		${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/export-ports.sh
	@sudo chmod 700 ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/export-ports.sh
	@sudo cp ${REGGAE_PATH}/templates/xorg.sh ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d
	@sudo sed -i "" \
		-e "s:XORG:${XORG}:g" \
		${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/xorg.sh
	@sudo chmod 700 ${CBSD_WORKDIR}/jails-system/${SERVICE}/master_poststart.d/xorg.sh
.if !exists(${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos)
	@sudo mkdir -p ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos
	@sudo sh -c 'echo -e FreeBSD: { url: \"pkg+http://${PKG_MIRROR}/\$${ABI}/${PKG_REPO}\"\; } >${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/pkg/repos/FreeBSD.conf'
.endif
.if target(post_create)
	@${MAKE} ${MAKEFLAGS} post_create
.endif

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

.if target(do_devel)
devel: up do_devel
.else
devel: up
.if defined(offline)
	@sudo cbsd jexec jname=${SERVICE} user=devel cmd="/usr/src/bin/devel.sh ${offline}"
.else
	@sudo cbsd jexec jname=${SERVICE} user=devel cmd=/usr/src/bin/devel.sh
.endif
.endif

test: up
	@sudo jexec -U devel ${SERVICE} /usr/src/bin/test.sh

upgrade: up
	@sudo cbsd jexec jname=${SERVICE} pkg upgrade -y

do-provision:
	@sudo mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/minion.d >/dev/null 2>&1 || true
	@sudo mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/usr/local/etc/salt/states >/dev/null 2>&1 || true
	@sudo ${REGGAE_PATH}/scripts/salt-provision.sh ${SERVICE}

post-up:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y py36-salt

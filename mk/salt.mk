MASTER = "salt.${DOMAIN}"

do-provision:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y py36-salt
	@sudo mkdir ${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/salt/minion.d >/dev/null 2>&1 || true
	@sudo sh -c "echo master: ${MASTER} >${CBSD_WORKDIR}/jails-data/${SERVICE}-data/usr/local/etc/salt/minion.d/master.conf"
	@sudo sh -c "echo salt_minion_enable=\"YES\" >${CBSD_WORKDIR}/jails-data/${SERVICE}-data//etc/rc.conf.d/salt_minion"
	@sudo cbsd jexec jname=${SERVICE} service salt_minion restart

do-clean:
	@echo "Remove from master"

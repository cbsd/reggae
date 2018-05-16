do-provision:
	@sudo ${REGGAE_PATH}/scripts/chef-provision.sh ${SERVICE}

post-up:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y rubygem-chef
	@sudo mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/etc/chef >/dev/null 2>&1 || true
	@sudo mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/root/chef >/dev/null 2>&1 || true

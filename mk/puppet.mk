do-provision:
	@sudo ${REGGAE_PATH}/scripts/puppet-provision.sh ${SERVICE}

post-up:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y puppet5

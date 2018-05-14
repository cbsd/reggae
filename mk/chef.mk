do-provision:
	@sudo ${REGGAE_PATH}/scripts/chef-provision.sh ${SERVICE}

post-up:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y rubygem-chef

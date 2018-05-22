PROVISIONERS += puppet

provision-puppet:
	@sudo ${REGGAE_PATH}/scripts/puppet-provision.sh ${SERVICE}

post-up:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y puppet5

clean-puppet:

setup-puppet:

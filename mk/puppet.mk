PROVISIONERS += puppet

provision-puppet:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y puppet5
	@sudo ${REGGAE_PATH}/scripts/puppet-provision.sh ${SERVICE}

clean-puppet:

setup-puppet:

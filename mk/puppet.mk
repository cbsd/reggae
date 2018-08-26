PROVISIONERS += puppet

provision-puppet:
	@sudo ${REGGAE_PATH}/scripts/puppet-provision.sh ${SERVICE} ${TYPE}

clean-puppet:

setup-puppet:

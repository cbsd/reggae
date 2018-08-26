PROVISIONERS += salt

provision-salt:
	@sudo ${REGGAE_PATH}/scripts/salt-provision.sh ${SERVICE} ${TYPE}

clean-salt:

setup-salt:

PROVISIONERS += chef

provision-chef:
	@sudo ${REGGAE_PATH}/scripts/chef-provision.sh ${SERVICE} ${TYPE}

clean-chef:

setup-chef:

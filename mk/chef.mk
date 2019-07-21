.include <${REGGAE_PATH}/mk/common.mk>

PROVISIONERS += chef

provision-chef:
	@sudo ${REGGAE_PATH}/scripts/chef-provision.sh ${SERVICE} ${TYPE}

clean-chef:

setup-chef:
.if target(post_setup_chef)
	@${MAKE} ${MAKEFLAGS} post_setup_chef
.endif

.include <${REGGAE_PATH}/mk/common.mk>

PROVISIONERS += salt

provision-salt:
	@sudo ${REGGAE_PATH}/scripts/salt-provision.sh ${SERVICE} ${TYPE}

clean-salt:

setup-salt:
.if target(post_setup_salt)
	@${MAKE} ${MAKEFLAGS} post_setup_salt
.endif

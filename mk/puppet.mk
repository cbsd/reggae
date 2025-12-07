.include <${REGGAE_PATH}/mk/common.mk>

PROVISIONERS += puppet

provision-puppet:
	@mdo ${REGGAE_PATH}/scripts/puppet-provision.sh ${SERVICE} ${TYPE}

clean-puppet:

setup-puppet:
.if target(post_setup_puppet)
	@${MAKE} ${MAKEFLAGS} post_setup_puppet
.endif

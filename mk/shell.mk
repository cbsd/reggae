.include <${REGGAE_PATH}/mk/common.mk>

PROVISIONERS += shell

provision-shell:
	@mdo ${REGGAE_PATH}/scripts/shell-provision.sh ${SERVICE} ${TYPE}

clean-shell:

setup-shell:
.if target(post_setup_shell)
	@${MAKE} ${MAKEFLAGS} post_setup_shell
.endif

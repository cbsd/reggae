.include <${REGGAE_PATH}/mk/common.mk>

PROVISIONERS += shell

provision-shell:
.if ${TYPE} == jail
	@sudo mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/root/shell >/dev/null 2>&1 || true
.endif
	@sudo ${REGGAE_PATH}/scripts/shell-provision.sh ${SERVICE} ${TYPE}

clean-shell:

setup-shell:
.if target(post_setup_shell)
	@${MAKE} ${MAKEFLAGS} post_setup_shell
.endif

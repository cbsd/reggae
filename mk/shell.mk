do-provision:
.if ${FOR_DEVEL_MODE} == YES
	@sudo ${REGGAE_PATH}/scripts/shell-provision.sh ${SERVICE} devel
.else
	@sudo ${REGGAE_PATH}/scripts/shell-provision.sh ${SERVICE}
.endif

PROVISIONERS += shell

provision-shell:
.if ${TYPE} == jail
	@sudo mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/root/shell >/dev/null 2>&1 || true
.endif
	@sudo ${REGGAE_PATH}/scripts/shell-provision.sh ${SERVICE} ${TYPE}

clean-shell:

setup-shell:

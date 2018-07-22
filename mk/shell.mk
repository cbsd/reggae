PROVISIONERS += shell

provision-shell:
	@sudo mkdir ${CBSD_WORKDIR}/jails/${SERVICE}/root/shell >/dev/null 2>&1 || true
	@sudo ${REGGAE_PATH}/scripts/shell-provision.sh ${SERVICE}

clean-shell:

setup-shell:

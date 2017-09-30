.if exists(vars.mk)
.include <vars.mk>
.endif

UID ?= 1001
GID ?= 1001
DOMAIN ?= example.com

.MAIN: up

up: setup
	@sudo cbsd jcreate jconf=${PWD}/cbsd.conf || true
.if !exists(/cbsd/jails-system/${SERVICE}/master_poststart.d/register.sh)
	@sudo ln -s /usr/local/bin/reggae /cbsd/jails-system/${SERVICE}/master_poststart.d/register.sh
.endif
.if !exists(/cbsd/jails-system/${SERVICE}/master_poststop.d/deregister.sh)
	@sudo ln -s /usr/local/bin/reggae /cbsd/jails-system/${SERVICE}/master_poststop.d/deregister.sh
.endif
	@sudo cbsd jstart ${SERVICE} || true
	@sudo chown ${UID}:${GID} cbsd.conf
.if !exists(.provisioned)
	@${MAKE} ${MAKEFLAGS} provision
.endif

provision:
	@touch .provisioned
.if target(do_provision)
	@${MAKE} ${MAKEFLAGS} do_provision
.endif

down: setup
	@sudo cbsd jstop ${SERVICE} || true

destroy: down
	@rm -f cbsd.conf vars.mk .provisioned
	@sudo cbsd jremove ${SERVICE}
.if target(do_clean)
	@${MAKE} ${MAKEFLAGS} do_clean
.endif

setup:
	@sed -e "s:SERVICE:${SERVICE}:g" -e "s:DOMAIN:${DOMAIN}:g" ${REGGAE_PATH}/templates/cbsd.conf.tpl >cbsd.conf
.if target(do_setup)
	@${MAKE} ${MAKEFLAGS} do_setup
.endif

login:
	@sudo cbsd jlogin ${SERVICE}

exec:
	@sudo cbsd jexec jname=${SERVICE} ${command}

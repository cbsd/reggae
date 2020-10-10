.if exists(vars.mk)
.include <vars.mk>
.endif

DEVEL_MODE ?= "NO"
RUNNING_UID := `id -u`
RUNNING_GID := `id -g`
UID ?= ${RUNNING_UID}
GID ?= ${RUNNING_GID}
USE_FREENIT ?= NO

.if ${USE_FREENIT} == "YES"
.include <${REGGAE_PATH}/mk/frameworks/freenit.project.mk>
.endif

.MAIN: up

.if target(pre_up)
up: fetch setup pre_up
.else
up: fetch setup
.endif
.if defined(service)
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} up
.else
.for service url in ${SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} up
.endfor
.endif

provision:
.if defined(service)
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} provision
.else
.for service url in ${SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} provision
.endfor
.endif

init:
.if !exists(services)
	@mkdir services
.endif

fetch:
.for service url in ${SERVICES}
.if !exists(services/${service})
	@git clone ${url} services/${service}
.endif
.endfor
.for repo url in ${EXTRA_REPOS}
.if !exists(repos/${repo})
	@git clone ${url} repos/${repo}
.endif
.endfor

.if target(pre_setup)
setup: pre_setup
.else
setup:
.endif
	@sudo rm -f services/*/cbsd.conf
.for service url in ${SERVICES}
	@rm -f services/${service}/project.mk
	@echo "DEVEL_MODE ?= ${DEVEL_MODE}" >>services/${service}/project.mk
	@echo "GID ?= ${GID}" >>services/${service}/project.mk
	@echo "UID ?= ${UID}" >>services/${service}/project.mk
.endfor
.if target(post_setup)
	@${MAKE} ${MAKEFLAGS} post_setup
.endif

.if target(do_devel)
devel: up do_devel
.else
devel: up
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} devel offline=${offline}
.else
	@env OFFLINE=${offline} bin/devel.sh reggae
.endif
.endif

test: up
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} test
.else
.for service url in ${SERVICES}
	@${MAKE} ${MAKEFLAGS} -C services/${service} test
.endfor
.endif

destroy:
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.else
.for url service in ${SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.endfor
.endif

login:
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} login
.else
	@sudo cbsd jlogin
.endif

down: setup
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.else
.for url service in ${SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.endfor
.endif

export:
.if defined(service)
	@echo "exporting ${service}"
	@${MAKE} ${MAKEFLAGS} -C services/${service} export
.else
.for service url in ${SERVICES}
	@echo "exporting ${service}"
	@${MAKE} ${MAKEFLAGS} -C services/${service} export
.endfor
.endif

update: fetch
	@git pull
.for service url in ${SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} update
.endfor

upgrade:
.for service url in ${SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} upgrade
.endfor

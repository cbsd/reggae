.if exists(vars.mk)
.include <vars.mk>
.endif

DEVEL_MODE ?= "NO"
RUNNING_UID := `id -u`
RUNNING_GID := `id -g`
UID ?= ${RUNNING_UID}
GID ?= ${RUNNING_GID}

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
	git clone ${url} services/${service}
.endif
.endfor

setup:
	@sudo rm -f services/*/cbsd.conf
.for service url in ${SERVICES}
	@rm -f services/${service}/vars.mk
	@echo "DEVEL_MODE ?= ${DEVEL_MODE}" >>services/${service}/vars.mk
	@echo "GID ?= ${GID}" >>services/${service}/vars.mk
	@echo "UID ?= ${UID}" >>services/${service}/vars.mk
.endfor
.if target(post_setup)
	@${MAKE} ${MAKEFLAGS} post_setup
.endif

devel: up
.if defined(service)
.if defined(offline)
	@${MAKE} ${MAKEFLAGS} -C services/${service} devel offline=${offline}
.else
	@${MAKE} ${MAKEFLAGS} -C services/${service} devel
.endif
.else
.if defined(offline)
	@env OFFLINE=${offline} bin/devel.sh
.else
	@bin/devel.sh
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

update:
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

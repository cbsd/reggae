DOMAIN ?= my.domain
STAGE ?= prod
RUNNING_UID := `id -u`
RUNNING_GID := `id -g`
UID ?= ${RUNNING_UID}
GID ?= ${RUNNING_GID}

all: fetch setup
.if defined(service)
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service}
.else
.for service url in ${SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service}
.endfor
.endif

up: fetch setup
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
.for service url in ${SERVICES}
	@rm -f services/${service}/vars.mk
	@echo "DOMAIN ?= ${DOMAIN}" >>services/${service}/vars.mk
	@echo "GID ?= ${GID}" >>services/${service}/vars.mk
	@echo "STAGE ?= ${STAGE}" >>services/${service}/vars.mk
	@echo "UID ?= ${UID}" >>services/${service}/vars.mk
.endfor

destroy:
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.else
.for url service in ${SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.endfor
.endif

login:
	@${MAKE} ${MAKEFLAGS} -C services/${service} login

down: setup
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.else
.for url service in ${SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.endfor
.endif

.if exists(vars.mk)
.include <vars.mk>
.endif

DEVEL_MODE ?= "NO"
RUNNING_UID := `id -u`
RUNNING_GID := `id -g`
UID ?= ${RUNNING_UID}
GID ?= ${RUNNING_GID}
VERSION ?= "native"
USE_FREENIT ?= NO

.if ${USE_FREENIT} == "YES"
.include <${REGGAE_PATH}/mk/frameworks/freenit.project.mk>
.endif
.include <${REGGAE_PATH}/mk/use.mk>

dependencies := NO

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
.for service url in ${ALL_SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} up
.endfor
.endif

provision:
.if defined(service)
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} provision
.else
.for service url in ${ALL_SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} provision
.endfor
.endif

init:
.if !exists(services)
	@mkdir services
.endif

fetch:
.for service url in ${ALL_SERVICES}
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
.for service url in ${ALL_SERVICES}
	@rm -f services/${service}/project.mk
	@echo "DEVEL_MODE ?= ${DEVEL_MODE}" >>services/${service}/project.mk
	@echo "GID ?= ${GID}" >>services/${service}/project.mk
	@echo "UID ?= ${UID}" >>services/${service}/project.mk
	@echo "VERSION ?= ${VERSION}" >>services/${service}/project.mk
.endfor
.if target(post_setup)
	@${MAKE} ${MAKEFLAGS} post_setup
.endif

devel_check:
.if ${DEVEL_MODE} != "YES"
	@echo "DEVEL_MODE must be set to YES"
	@exit 1
.endif

.if target(do_devel)
devel: devel_check up do_devel
.else
devel: devel_check up
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} devel offline=${offline}
.else
	@env OFFLINE=${offline} REGGAE=yes bin/devel.sh `make service_names`
.endif
.endif

test: up
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} OFFLINE=${offline} test
.else
.for service url in ${SERVICES}
	@${MAKE} ${MAKEFLAGS} -C services/${service} OFFLINE=${offline} test
.endfor
.endif

destroy:
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.else
.if ${dependencies} == "yes"
.for url service in ${POST_SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.endfor
.endif
.for url service in ${SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.endfor
.if ${dependencies} == "yes"
.for url service in ${USED_SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.endfor
.for url service in ${PRE_SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} destroy
.endfor
.endif
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
.if ${dependencies} == "yes"
.for url service in ${POST_SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.endfor
.endif
.for url service in ${SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.endfor
.if ${dependencies} == "yes"
.for url service in ${USED_SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.endfor
.for url service in ${PRE_SERVICES:[-1..1]}
	@${MAKE} ${MAKEFLAGS} -C services/${service} down
.endfor
.endif
.endif

export:
.if defined(service)
	@echo "exporting ${service}"
	@${MAKE} ${MAKEFLAGS} -C services/${service} export
.else
.if ${dependencies} == "yes"
.for service url in ${ALL_SERVICES}
	@echo "exporting ${service}"
	@${MAKE} ${MAKEFLAGS} -C services/${service} export
.endfor
.else
.for service url in ${SERVICES}
	@echo "exporting ${service}"
	@${MAKE} ${MAKEFLAGS} -C services/${service} export
.endfor
.endif
.endif

update: fetch
	@git pull
.if ${dependencies} == "yes"
.for service url in ${ALL_SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} update
.endfor
.else
.for service url in ${SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} update
.endfor
.endif

upgrade:
.for service url in ${SERVICES}
	@echo "=== ${service} ==="
	@${MAKE} ${MAKEFLAGS} -C services/${service} upgrade
.endfor

print_services:
.if ${dependencies} == "yes"
	@echo ${ALL_SERVICES}
.else
	@echo ${SERVICES}
.endif

service_names:
.if ${dependencies} == "yes"
.for service url in ${ALL_SERVICES}
	@echo ${service}
.endfor
.else
.for service url in ${SERVICES}
	@echo ${service}
.endfor
.endif

service_urls:
.if ${dependencies} == "yes"
.for service url in ${ALL_SERVICES}
	@echo ${url}
.endfor
.else
.for service url in ${SERVICES}
	@echo ${url}
.endfor
.endif

.if ${dependencies} == "yes"
restart:
	@${MAKE} ${MAKEFLAGS} down dependencies=yes
	@${MAKE} ${MAKEFLAGS} up
.else
restart: down up
.endif

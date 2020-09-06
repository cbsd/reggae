shell: up
	@sudo cbsd jexec user=devel jname=${SERVICE} /usr/src/bin/shell.sh

init: up
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/init.sh

do_devel: init
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} BACKEND_URL=${BACKEND_URL} /usr/src/bin/devel.sh

collect:
	@rm -rf build
	@mkdir -p build
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/collect.sh

do_publish:
	@/bin/sh bin/publish.sh ${server} ${SERVICE}

build_lib: up
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/build.sh

publish_lib: build_lib
	@sudo cbsd jexec jname=${SERVICE} user=devel /usr/src/bin/publish.sh

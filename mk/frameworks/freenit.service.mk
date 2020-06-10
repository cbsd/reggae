shell: up
	@sudo cbsd jexec user=devel jname=${SERVICE} /usr/src/bin/shell.sh

init: up
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/init.sh

do_devel:
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/devel.sh


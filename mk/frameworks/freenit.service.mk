.if !target(shell)
shell: up
	@sudo cbsd jexec user=devel jname=${SERVICE} /usr/src/bin/shell.sh
.endif

init: up
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/init.sh

do_devel: init
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} BACKEND_URL=${BACKEND_URL} /usr/src/bin/devel.sh

.if !target(collect)
collect:
	@rm -rf build
	@mkdir -p build
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/collect.sh
.endif

.if !target(publish)
publish: collect
.if !defined(server)
	@echo "Usage: make publish server=<server> domain=<domain>"
	@fail
.endif
.if !defined(domain)
	@echo "Usage: make publish server=<server> domain=<domain>"
	@fail
.endif
	@reggae read-pass >passwd
	@echo
	@reggae expect-run passwd Password: ssh -t provision@${server} sudo cbsd jexec jname=${SERVICE} sudo -u uwsgi git -C /usr/local/repos/${SERVICE} fetch
	@reggae expect-run passwd Password: ssh -t provision@${server} sudo cbsd jexec jname=${SERVICE} sudo -u uwsgi git -C /usr/local/repos/${SERVICE} reset --hard origin/master
	@reggae expect-run passwd Password: ssh -t provision@${server} sudo cbsd jexec jname=${SERVICE} sudo -u uwsgi env SYSPKG=${SYSPKG} /usr/local/repos/${SERVICE}/bin/init.sh
	@reggae expect-run passwd Password: ssh -t provision@${server} sudo cbsd jexec jname=${SERVICE} service uwsgi restart
	@rm -rf passwd
.endif

do_publish:
	@/bin/sh bin/publish.sh ${server} ${SERVICE}

build_lib: up
	@sudo cbsd jexec jname=${SERVICE} user=devel env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/build.sh

publish_lib: build_lib
	@sudo cbsd jexec jname=${SERVICE} user=devel /usr/src/bin/publish.sh

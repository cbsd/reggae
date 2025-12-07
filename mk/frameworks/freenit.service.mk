.if !target(shell)
shell: up
	@mdo reggae jexec -U devel ${SERVICE} /usr/src/bin/shell.sh
.endif

do_devel:
	@mdo reggae jexec -U devel ${SERVICE} env OFFLINE=${offline} SYSPKG=${SYSPKG} BACKEND_URL=${BACKEND_URL} /usr/src/bin/devel.sh

.if !target(collect)
collect:
	@rm -rf build
	@mkdir -p build
	@mdo reggae jexec -U devel ${SERVICE} env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/collect.sh
.endif

build_lib: up
	@mdo reggae jexec -U devel ${SERVICE} env OFFLINE=${offline} SYSPKG=${SYSPKG} /usr/src/bin/build.sh

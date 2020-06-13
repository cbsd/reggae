build_lib: up
	@bin/build.sh

publish:
.if defined(server)
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} server=${server} publish
.else
.for service url in ${SERVICES}
	@${MAKE} ${MAKEFLAGS} -C services/${service} up collect
.endfor
	@bin/publish.sh ${server}
.endif
.else
	@echo "Usage: make publish server=<server>"
	@fail
.endif

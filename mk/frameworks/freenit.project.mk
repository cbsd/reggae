.if !target(collect)
collect: up
	@bin/collect.sh
.endif

.if !target(publish)
publish:
.if !defined(server)
	@echo "Usage: make publish server=<server> domain=<domain>"
	@fail
.endif
.if !defined(domain)
	@echo "Usage: make publish server=<server> domain=<domain>"
	@fail
.endif
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} server=${server} publish
.else
.for service url in ${SERVICES}
	@make -C services/${service} publish server=${server} domain=${domain}
.endfor
.endif
.endif

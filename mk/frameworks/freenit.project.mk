.if !target(collect)
collect: up
	@bin/collect.sh
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
.if defined(service)
	@${MAKE} ${MAKEFLAGS} -C services/${service} server=${server} publish
.else
	@rsync -avc --progress --delete-after build/ deploy@${server}:/usr/cbsd/jails-data/nginx-data/usr/local/www/${domain}/
	@make -C services/backend publish server=${server}
.endif
.endif

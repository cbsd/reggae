BIN=/bin
PREFIX?=/usr/local
TEMPLATE_DIR=/share/cbsd-devops/templates

BIN_FILES = cbsd-devops
TEMPLATES = register.tpl

all:
	@echo 'Finished'

install: install_bin install_templates

install_bin:
	install -d ${DESTDIR}${PREFIX}${BIN}
.for bin_file in ${BIN_FILES}
	install bin/${bin_file} ${DESTDIR}${PREFIX}${BIN}
.endfor

install_templates:
	install -d ${DESTDIR}${PREFIX}${TEMPLATE_DIR}
.for template_file in ${TEMPLATES}
	install -m 0644 templates/${template_file} ${DESTDIR}${PREFIX}${TEMPLATE_DIR}
.endfor

BIN = /bin
PREFIX ?= /usr/local
TEMPLATE_DIR = /share/reggae/templates
MAKE_DIR = /share/reggae/mk
SCRIPTS_DIR = /share/reggae/scripts
BIN_FILES = reggae
TEMPLATES = register.tpl \
	    cbsd.conf.tpl \
	    register.sh \
	    deregister.sh \
	    initenv.conf \
	    consul.conf
PLAYBOOK_TEMPLATES = playbook/inventory.tpl
PLAYBOOK_GROUP_TEMPLATES = playbook/group_vars/all.tpl
MAKEFILES = ansible.mk \
	    project.mk \
	    service.mk
SCRIPTS = init.sh \
	  register.sh
MAN_FILES = reggae.1 \
	    reggae-ansible.1 \
	    reggae-init.1 \
	    reggae-register.1


all: compress_man
	@echo 'Finished'

compress_man:
.for man_file in ${MAN_FILES}
	gzip -f -k man/${man_file}
.endfor

install: install_bin install_templates install_makefiles install_scripts install_man

install_bin:
	install -d ${DESTDIR}${PREFIX}${BIN}
.for bin_file in ${BIN_FILES}
	install -m 0755 bin/${bin_file} ${DESTDIR}${PREFIX}${BIN}
.endfor

install_templates:
	install -d ${DESTDIR}${PREFIX}${TEMPLATE_DIR}
	install -d ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/playbook
	install -d ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/playbook/group_vars
.for template_file in ${TEMPLATES}
	install -m 0644 templates/${template_file} ${DESTDIR}${PREFIX}${TEMPLATE_DIR}
.endfor
.for template_file in ${PLAYBOOK_TEMPLATES}
	install -m 0644 templates/${template_file} ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/playbook
.endfor
.for template_file in ${PLAYBOOK_GROUP_TEMPLATES}
	install -m 0644 templates/${template_file} ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/playbook/group_vars
.endfor

install_makefiles:
	install -d ${DESTDIR}${PREFIX}${MAKE_DIR}
.for make_file in ${MAKEFILES}
	install -m 0644 mk/${make_file} ${DESTDIR}${PREFIX}${MAKE_DIR}
.endfor

install_scripts:
	install -d ${DESTDIR}${PREFIX}${SCRIPTS_DIR}
.for script_file in ${SCRIPTS}
	install -m 0755 scripts/${script_file} ${DESTDIR}${PREFIX}${SCRIPTS_DIR}
.endfor

install_man:
	install -d ${DESTDIR}${PREFIX}/man/man1
.for man_file in ${MAN_FILES}
	install -m 0644 man/${man_file}.gz ${DESTDIR}${PREFIX}/man/man1
.endfor

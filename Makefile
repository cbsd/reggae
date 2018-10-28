BIN = /bin
PREFIX ?= /usr/local
REGGAE_DIR ?= share/reggae
TEMPLATE_DIR = /${REGGAE_DIR}/templates
MAKE_DIR = /${REGGAE_DIR}/mk
SCRIPTS_DIR = /${REGGAE_DIR}/scripts
CBSD_PROFILE_DIR = /${REGGAE_DIR}/cbsd-profile
BIN_FILES = reggae
TEMPLATES = cbsd.conf.tpl \
	    dhcp.conf \
	    dhcpd.conf \
	    dhcpd-hook.sh \
	    freebsd-update.conf \
	    gitignore \
	    initenv.conf \
	    install-packages.sh \
	    ip-by-mac.sh \
	    empty.jconf \
	    mount-project.sh \
	    my.domain \
	    my.domain.rev \
	    named.conf \
	    nsupdate-add.txt \
	    nsupdate-delete.txt \
	    pf.conf \
	    rndc.conf \
	    resolvconf.conf \
	    resolver.conf \
	    setup-vm.sh \
	    Makefile.project \
	    Makefile.service \
	    unbound.conf \
	    unbound_cbsd.conf
ANSIBLE_TEMPLATES = ansible/inventory.local.tpl ansible/inventory.remote.tpl
ANSIBLE_GROUP_TEMPLATES = ansible/group_vars/all.tpl
MAKEFILES = ansible.mk \
	    common.mk \
	    bhyve-service.mk \
	    chef.mk \
	    jail-service.mk \
	    project.mk \
	    puppet.mk \
	    salt.mk \
	    shell.mk \
	    service.mk
SCRIPTS = bhyve-init.sh \
	  cbsd-init.sh \
	  chef-provision.sh \
	  get-config.sh \
	  get-ip.sh \
	  import.sh \
	  init.sh \
	  master-init.sh \
	  network-init.sh \
	  puppet-provision.sh \
	  project-init.sh \
	  register.sh \
	  salt-provision.sh \
	  scp.sh \
	  shell-provision.sh \
	  ssh.sh \
	  ssh-ping.sh
MAN_FILES = reggae.1 \
	    reggae-ansible.1 \
	    reggae-chef.1 \
	    reggae-project.1 \
	    reggae-provision.1 \
	    reggae-puppet.1 \
	    reggae-register.1 \
	    reggae-salt.1 \
	    reggae-service.1
CBSD_PROFILE_ITEMS = skel \
		     system \
		     reggae-jail.conf


all: compress_man

compress_man:
.for man_file in ${MAN_FILES}
	gzip -f -k man/${man_file}
.endfor

install: install_bin install_templates install_makefiles install_scripts install_man install_profile
	install -d ${DESTDIR}${PREFIX}/etc
	install -m 0644 reggae.conf.sample ${DESTDIR}${PREFIX}/etc
	install -m 0600 id_rsa id_rsa.pub ${DESTDIR}${PREFIX}/${REGGAE_DIR}
	install -m 0644 scripts/default.conf ${DESTDIR}${PREFIX}${SCRIPTS_DIR}/default.conf
	cp -r skel ${DESTDIR}${PREFIX}/${REGGAE_DIR}

install_bin:
	install -d ${DESTDIR}${PREFIX}${BIN}
.for bin_file in ${BIN_FILES}
	install -m 0755 bin/${bin_file} ${DESTDIR}${PREFIX}${BIN}
.endfor

install_templates:
	install -d ${DESTDIR}${PREFIX}${TEMPLATE_DIR}
	install -d ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/ansible
	install -d ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/ansible/group_vars
.for template_file in ${TEMPLATES}
	install -m 0644 templates/${template_file} ${DESTDIR}${PREFIX}${TEMPLATE_DIR}
.endfor
.for template_file in ${ANSIBLE_TEMPLATES}
	install -m 0644 templates/${template_file} ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/ansible
.endfor
.for template_file in ${ANSIBLE_GROUP_TEMPLATES}
	install -m 0644 templates/${template_file} ${DESTDIR}${PREFIX}${TEMPLATE_DIR}/ansible/group_vars
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

install_profile:
	install -d ${DESTDIR}${PREFIX}${CBSD_PROFILE_DIR}
	cp -r cbsd-profile/* ${DESTDIR}${PREFIX}${CBSD_PROFILE_DIR}/

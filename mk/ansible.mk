.include <${REGGAE_PATH}/mk/common.mk>

PROVISIONERS += ansible
ANSIBLE != sh -c "which ansible || true"

provision-ansible: setup-ansible
	@sudo rm -rf ansible/site.retry
	@-sudo chown -R ${UID}:${GID} ~/.ansible
.if exists(requirements.yml)
	@ansible-galaxy install -p ansible/roles -r requirements.yml
.endif
.if defined(server)
	@sudo env ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/inventory/inventory ansible/site.yml -b --ssh-extra-args='"-o ProxyCommand ssh -x -a -q ${server} nc %h 22"'
.elif ${TYPE} == bhyve
	@sudo env ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --become -i ansible/inventory/inventory ansible/site.yml
.else
	@sudo ansible-playbook -i ansible/inventory/inventory ansible/site.yml
.endif

setup-ansible:
	@sed -e "s:SERVICE:${SERVICE}:g" ${REGGAE_PATH}/templates/ansible/group_vars/all.tpl >ansible/group_vars/all
.if defined(server)
	@sed -e "s:SERVICE:${SERVICE}.${server}:g" ${REGGAE_PATH}/templates/ansible/inventory.remote.tpl >ansible/inventory/inventory
	@sed -e "s:SERVICE:${SERVICE}.${server}:g" templates/site.yml.tpl >ansible/site.yml
.elif ${TYPE} == bhyve
	@sed -e "s:SERVICE:`sudo reggae get-ip ${SERVICE}`:g" ${REGGAE_PATH}/templates/ansible/inventory.remote.tpl >ansible/inventory/inventory
	@sed -e "s:SERVICE:`sudo reggae get-ip ${SERVICE}`:g" templates/site.yml.tpl >ansible/site.yml
.else
	@sed -e "s:SERVICE:${SERVICE}:g" ${REGGAE_PATH}/templates/ansible/inventory.local.tpl >ansible/inventory/inventory
	@sed -e "s:SERVICE:${SERVICE}:g" templates/site.yml.tpl >ansible/site.yml
.endif
.if !exists(ansible/roles)
	@mkdir ansible/roles
.endif
.if ${ANSIBLE:M*} == ""
	@echo
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!! No ansible binary on the host !!!"
	@echo "!!! Trying to install one         !!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo
	@sudo pkg install py36-ansible
.endif
.if target(post_setup_ansible)
	@${MAKE} ${MAKEFLAGS} post_setup_ansible
.endif

clean-ansible:
	@rm -rf ansible/inventory/inventory ansible/site.yml ansible/group_vars/all

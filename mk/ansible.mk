.include <${REGGAE_PATH}/mk/common.mk>

PROVISIONERS += ansible
ANSIBLE != sh -c "which ansible-3.6 || true"

provision-ansible:
	@sudo rm -rf ansible/site.retry
	@-sudo chown -R ${UID}:${GID} ~/.ansible
.if exists(requirements.yml)
	@ansible-galaxy-3.6 install -p ansible/roles -r requirements.yml
.endif
.if defined(server)
	@env ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook-3.6 -i ansible/inventory/inventory ansible/site.yml -b --ssh-extra-args='"-o ProxyCommand ssh -x -a -q ${server} nc %h 22"'
.elif ${TYPE} == bhyve
	@env ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook-3.6 --become -i ansible/inventory/inventory ansible/site.yml
.else
	@sudo ansible-playbook-3.6 -i ansible/inventory/inventory ansible/site.yml
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

clean-ansible:
	@rm -rf ansible/inventory/inventory ansible/site.yml ansible/group_vars/all

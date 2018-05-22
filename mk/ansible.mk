ANSIBLE!=sh -c "which ansible || true"

do-provision:
.if exists(requirements.yml)
	@ansible-galaxy install -p ansible/roles -r requirements.yml
.endif
	@sudo cbsd jexec jname=${SERVICE} pkg install -y python
	@sudo ansible-playbook -i ansible/inventory/inventory ansible/site.yml

do-setup:
	@sed -e "s:SERVICE:${SERVICE}:g" ${CUSTOM_TEMPLATES}/site.yml.tpl >ansible/site.yml
	@sed -e "s:SERVICE:${SERVICE}:g" ${REGGAE_PATH}/templates/ansible/inventory.tpl >ansible/inventory/inventory
	@sed -e "s:SERVICE:${SERVICE}:g" -e "s:DOMAIN:${DOMAIN}:g" ${REGGAE_PATH}/templates/ansible/group_vars/all.tpl >ansible/group_vars/all
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
	@sudo pkg install ansible
.endif

do-clean:
	@rm -rf ansible/inventory/inventory ansible/site.yml ansible/group_vars/all

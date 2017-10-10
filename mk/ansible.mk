do_provision:
	@sudo ansible-playbook -i playbook/inventory/inventory playbook/site.yml

do_setup:
	@sed -e "s:SERVICE:${SERVICE}:g" ${CUSTOM_TEMPLATES}/site.yml.tpl >playbook/site.yml
	@sed -e "s:SERVICE:${SERVICE}:g" ${REGGAE_PATH}/templates/playbook/inventory.tpl >playbook/inventory/inventory
	@sed -e "s:SERVICE:${SERVICE}:g" -e "s:DOMAIN:${DOMAIN}:g" ${REGGAE_PATH}/templates/playbook/group_vars/all.tpl >playbook/group_vars/all
.if !exists(playbook/roles)
	@mkdir playbook/roles
.if exists(requirements.yml)
	@ansible-galaxy install -p playbook/roles -r requirements.yml
.endif
.endif

do_clean:
	@rm -rf playbook/inventory/inventory playbook/site.yml playbook/group_vars/all

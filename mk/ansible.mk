do_provision:
	@sudo ansible-playbook -i playbook/inventory/inventory playbook/site.yml

do_setup:
	@sed -e "s:SERVICE:${SERVICE}:g" ${CUSTOM_TEMPLATES}/site.yml.tpl >playbook/site.yml
	@sed -e "s:SERVICE:${SERVICE}:g" ${REGGAE_PATH}/templates/playbook/inventory.tpl >playbook/inventory/inventory
	@sed -e "s:SERVICE:${SERVICE}:g" -e "s:DOMAIN:${DOMAIN}:g" ${REGGAE_PATH}/templates/playbook/group_vars/all.tpl >playbook/group_vars/all

do_clean:
	@rm -f playbook/inventory/inventory playbook/site.yml playbook/group_vars/all

# Ansible Provisioner

To get started, create directory named `myservice` and inside it run `reggae init ansible`. It will be populated with the basic role so you can start writing more complex ones. Let's see what's inside:
* Makefile - configured for use with Ansible
* playbook - containing `group_vars`, `inventory` and `roles` directories as placeholders for files generated on the fly, but can be used to configure your playbook
* requirements.yml - list of requirements, with only one initially. All requirements from this file are downloaded from [Ansible Galaxy](https://galaxy.ansible.com)
* templates/site.yml.tpl - this file should be edited to add/remove roles, playbooks, etc.

When ran with this configuration, `reggae` will first check if `ansible` executable is available, and if it isn't, it will run `pkg install ansible`. If you use Python's virtual environments, for example, you can avoid having `ansible` available to everyone on the system.

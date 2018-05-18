# Salt Provisioner

To get started, create directory named `myservice` and inside it run `reggae init salt`. It will be populated with the basic script so you can start writing more complex ones. Let's see what's inside:
* Makefile - configured for use with Shell provisioner
* playbook - containing `top.sls` and `core.sls` playbooks

When ran with this configuration, `reggae` will first check if `salt` executable is available inside jail, and if it isn't, it will run `pkg install -y py36-salt` inside jail. Then it will mount playbook directory on `/usr/local/etc/salt/states` inside jail. To do actual provisioning, Reggae uses `salt-call --local state.apply`.

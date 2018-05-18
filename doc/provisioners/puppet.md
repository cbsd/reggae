# Puppet Provisioner

To get started, create directory named `myservice` and inside it run `reggae init puppet`. It will be populated with the basic role so you can start writing more complex ones. Let's see what's inside:
* Makefile - configured for use with Puppet
* playbook/site.pp - dummy role to start with

When ran with this configuration, `reggae` will first check if `puppet` executable is available inside jail, and if it isn't, it will install it from packages. Then it will mount `playbook` directory on `/usr/local/etc/puppet/manifests` inside jail. To do actual provisioning, Reggae uses `puppet apply`.

# Shell Provisioner

To get started, create directory named `myservice` and inside it run `reggae init shell`. It will be populated with the basic script so you can start writing more complex ones. Let's see what's inside:
* Makefile - configured for use with Chef provisioner
* playbook/cookbooks/core/recipes/default.rb - containing dummy provision.sh to start with

When ran with this configuration, `reggae` will first mount playbook directory on `/root/shell` inside jail. To do actual provisioning, Reggae will run `/root/shell/provision.sh`.

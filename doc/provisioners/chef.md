# Chef Provisioner

To get started, create directory named `myservice` and inside it run `reggae init chef`. It will be populated with the basic script so you can start writing more complex ones. Let's see what's inside:
* Makefile - configured for use with Shell provisioner
* playbook - containing `cookbooks/core/recipes/default.rb` dummy script

When ran with this configuration, `reggae` will first check if `chef-client` executable is available inside jail, and if it isn't, it will install it from packages. Then it will mount playbook directory on `/root/chef` inside jail. To do actual provisioning, Reggae uses `chef-client --local-mode`.

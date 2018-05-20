# Reggae Provisioners

Reggae supports following provisioners:
* [ansible](ansible.md)
* [chef](chef.md)
* [puppet](puppet.md)
* [salt](salt.md)
* [shell](shell.md)

To create a service with minimal provisioner skeleton, only slight modification in initialization is needed:
```
mkdir myservice
cd myservice
reggae init <provisioner>
```
Reggae will generate `playbook` directory where all files for your provisioner will be.

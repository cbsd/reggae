# Reggae
*REGister Globaly Access Everywhere* is a package which helps in common DevOps tasks relying on CBSD for management of jails and virtual machines on FreeBSD. If you ever used Vagrant, Reggae is best described as alternative to Vagrant. To use it, you have to install it and run `reggae init` which will setup your `bridge1` and `lo1` interfaces for its use. Once initialized you will need to redirect port to use Consul as DNS. Following is an example in PF:

```
jail_if = "lo1"
bridge_if = "bridge1"
consul = 127.0.2.1
nat on $ext_if from { ($jail_if:network), ($bridge_if:network) } to any -> ($ext_if)
rdr pass on $jail_if proto udp from any to any port 53 -> $consul port 8600
```

## Makefiles
There are two types of makefiles: services and projects. Service is single jail with a small set of apps running in it. If more than one jail is needed, use project. The following is the simplest service `Makefile`:

```
SERVICE = myservice
REGGAE_PATH = /usr/local/share/reggae
.include <${REGGAE_PATH}/mk/service.mk>
```

You can automatically provision your jail. Currently, only ansible provisioning is supported out of the box. First, you need to edit your `Makefile`:

```
SERVICE = myservice
REGGAE_PATH = /usr/local/share/reggae
CUSTOM_TEMPLATES = templates

.include <${REGGAE_PATH}/mk/ansible.mk>
.include <${REGGAE_PATH}/mk/service.mk>
```

Second, *Reggae* will expect this hierarchy:

- playbook/
  - inventory/
  - group_vars/
  - roles/
    - myservice/
      - tasks/
        - main.yml
- templates/
  - site.yml.tpl

Example of simple ansible tasks for `main.yml`:
```
---
- name: stop sendmail
  service:
    name: sendmail
    state: stopped
```

Example of `site.yml.tpl`:
```
---
- name: SERVICE provisioning
  hosts: SERVICE
  roles:
    - myservice
```

You need to install ansible on the host running provisioning. Typing `make` with such a service will create `myservice` CBSD jail and stop sendmail in it.

If you need multiple jails, easiest way to configure a project is to have your services as github repositories as described above and your project `Makefile` as following:
```
REGGAE_PATH = /usr/local/share/reggae
SERVICES = myservice https://github.com/<user>/jail-myservice \
           someother https://github.com/<user>/jail-someother

.include <${REGGAE_PATH}/mk/project.mk>
```
Running `make` will invoke `make up` and if it is the first time you run it, `make provision` will also be executed.

Supported make targets for project are:
* destroy
* devel service=\<service>
* fetch
* init
* login service=\<service>
* provision
* setup
* up

All project targets can be suffiexed with `service=<service>` but in the above list only those which require a service are explicitely mentioned. If the service is passed as an argument, the target will be executed only on that service/jail.

Supported make targets for service are:
* destroy
* devel
* exec
* export
* login
* provision
* setup
* up

Special note for `devel` target: your repo must have `bin/dev.sh` which devel will try to run.

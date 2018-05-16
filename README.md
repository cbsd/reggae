# Reggae
*REGister Globaly Access Everywhere* is a package which helps in common DevOps tasks relying on CBSD for management of jails and virtual machines on FreeBSD. If you have ever used Vagrant or Docker Compose, Reggae is best described as an alternative to those.

## Installation

To use Reggae you need to have the following packages installed: `cbsd` and `sqlite3`. CBSD needs to be configured beforehand as well. To install Reggae run:
```
git clone https://github.com/cbsd/reggae.git
cd reggae
make
make install
reggae network-init
# service pflog restart
# service pf restart
# service sshd restart
reggae cbsd-init
reggae master-init
```

Through config file in `/usr/local/etc/reggae.conf` you can choose to use non-default values for anything Reggae is using, and can use `/usr/local/etc/reggae.conf.sample` as a reference of all defaults options.

Or you can just [see it all in action](https://www.youtube.com/watch?v=6GPKO6Gp7b0&list=PLtcibmaW4u3tJj8m1bKH8TbmYWxayX5VC), first!

## Getting started

First, create empty directory for your jail/service and initialize it.
```
mkdir myservice
cd myservice
reggae init
```
It will create the simplest Reggae config. When you run `make`, you'll get jail named `myservice`. If you want to name it differently, change `SERVICE = myservice` line in `Makefile`.

Running `make` will invoke `make up` and if it is the first time you run it, `make provision` will also be executed.

Supported make targets for the service type are:
* destroy
* devel
* exec
* export
* login
* provision
* setup
* up

Special note for the `devel` target: your repo must have `bin/devel.sh` which be ran inside jail. Also, devel will only work if you have `DEVEL_MODE="YES"` in your vars.mk in service root. If you use it inside a project, project's `DEVEL_MODE` will be propagated.

Supported make targets for the project type are:
* destroy
* devel
* fetch
* init
* login service=\<service>
* provision
* setup
* up

Special note for the `devel` target: your repo must have `bin/devel.sh` which be ran on the host. All project targets can be suffixed with `service=<service>` but in the above list only those which require a service are explicitely mentioned. If the service is passed as an argument, the target will be executed only on that service/jail.

## Provisioners

Reggae supports following provisioners:
* ansible
* chef
* puppet
* salt
* shell

To create a service with minimal provisioner skeleton, only slight modification in initialization is needed:
```
mkdir myservice
cd myservice
reggae init <provisioner>
```
Reggae will generate `playbook` directory where all files for your provisioner will be.

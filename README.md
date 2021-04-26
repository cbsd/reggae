# Reggae
*REGister Globaly Access Everywhere* is a package which helps in common DevOps tasks relying on CBSD for management of jails and virtual machines on FreeBSD. If you have ever used Vagrant or Docker Compose, Reggae is best described as an alternative to those. It enables you easy development inside jail while code editing is done on the host. It makes transition from development to production easier by using provisioners. It makes host clean of all requirements of development environment and puts them inside jail which is easily stopped, started, provisioned, and destroyed. Using only `make` and `sh` on the system and `cbsd` and `sudo` from packages, makes it really small and easy to extend.

## Installation

To use Reggae you need to have the following packages installed: `cbsd` and `sqlite3`. To install Reggae run the following as root:
```
git clone https://github.com/cbsd/reggae.git
cd reggae
make
make install
reggae network-init
# service pflog restart
# service pf restart
reggae cbsd-init
reggae master-init
```

Through config file in `/usr/local/etc/reggae.conf` you can change values for anything Reggae is using. `reggae network-init` will make sure `sshd` is listening to lo0 on hosts with dynamic IP, and on lo0 and egress if the IP is static. This way host sshd doesn't have a conflict with the jailed one. Also, if IP is dynamic, PF will be configured so it redirects all requests for SSH on egress to lo0. One of the advantages is that you can use ssh's ProxyCommand to login to jail, even though jail is behind NAT.

Ater `reggae master-init`, you'll get two master jails: DHCP and DNS. They are used to lease IPs to virtual machines and to register all resources in DNS so that you can use FQDN instead of IP addresses. The DNS jail IP is used in /etc/resolvconf.conf if host has dynamic IP on egress, so that changes of network parameters are passed to the appropriate jail. Also, host will use DNS jail IP in /etc/resolv.conf. In short, it enables you to not remember jail IPs when you have to use them, but use `<jail name>.<domain>` to reference them, in which case <domain> comes from /usr/local/etc/reggae.conf.

Or you can just **[see it all in action](https://www.youtube.com/watch?v=6GPKO6Gp7b0&list=PLtcibmaW4u3tJj8m1bKH8TbmYWxayX5VC)**, first!

## Getting started

### Service

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

Special note for the `devel` target: your repo must have `bin/devel.sh` which be ran inside jail. Also, devel will only work if you have `DEVEL_MODE=YES` in your vars.mk in service root. If you use it inside a project, project's `DEVEL_MODE` will be propagated.

Service can be provisioned with the [supported provisioners](doc/provisioners), to speed up jail setup.

### Project

Create empty directory and initialize it.
```
mkdir myproject
cd myproject
reggae project-init
```
One project can contain many services, and that's going to be shown in the generated `Makefile`. The `SERVICES` variable in it will be commented but populated with example services. All services when downloaded will be in `services/<service>` directory.

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

For more info, check out the **[docs](doc)**!

# Documentation

To configure the host system, run `reggae host-init`. As it sets up PF, you
should `service pf restart` before continuing. As restarting PF will cut off
existing connections, Reggae will not do it on its own.

Next, you need to initialize the backend. Currently there are two backends
available:

* base
* cbsd

By default Reggae will use `base` which means only FreeBSD base tools are used.
To initialize base, run `reggae base-init` and to initialize CBSD run
`reggae cbsd-init`. It is perfectly valid to initialize both, but using jails
from different backends can be tricky. Usually, you will need only one backend.

The last in line to configure is network jail with DHCP and DNS services. The
command `reggae network-init` will do just that. You can configure backend
through `/usr/local/etc/reggae.conf` or through environment variable like
`env BACKEND=cbsd reggae network-init`.

* [Base Integration](base)
* [CBSD Integration](cbsd)
* [Provisioners](provisioners)

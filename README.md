# Reggae
*REGister Globaly Access Everywhere* is a package which helps in common DevOps tasks relying on CBSD for management of jails and virtual machines on FreeBSD. If you ever used Vagrant, Reggae is best described as alternative to Vagrant. To use it, you have to install it and run `reggae init` which will setup your `bridge1` and `lo1` interfaces for its use. Once initialized you will need to redirect port to use Consul as DNS. Following is an example in PF:

```
jail_if = "lo1"
consul = 127.0.2.1
rdr pass on $jail_if proto udp from any to any port 53 -> $consul port 8600
```

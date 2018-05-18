# CBSD integration

Although Reggae could leave CBSD config as it is, it's more suitable to have CBSD aware of Reggae config. Reggae configures hooks, profile and jail skel to run commands on CBSD actions or to make CBSD usable without Reggae.

By default, there is only one hook that Reggae installs and it does two things:
* registeres jail in DNS server
* add's jail IP to PF table (used for granting access and NAT)
DNS registration is done via RNDC and keys, while for /dev/pf access inside jail, special /etc/devfs.rules entry is made but only if /etc/devfs.rules doesn't exist already, so be carefull when doing custom configs: you have to add this in devfs:
```
[devfsrules_jail_bpf=7]
add include \$devfsrules_hide_all
add include \$devfsrules_unhide_basic
add include \$devfsrules_unhide_login
add path 'bpf*' unhide
add path 'pf*' unhide mode 0660 group 136
```
If /etc/pf.conf doesn't exist on host, it will be created from a template:
```
# Macros and tables
ext_if = "EGRESS"
# SyncThing example
# tcp_ports = "{ 22000, 3000 }"
# udp_ports = "{ 21027 }"
table <cbsd> persist

# Options
set block-policy drop
set skip on lo0

# Normalization
scrub in all

# NAT
nat on $ext_if from <cbsd> to any -> ($ext_if)
rdr pass on $ext_if proto tcp from any to any port ssh -> 127.0.0.1 # only on dhcp'ed egress

# Quick rules
antispoof quick for ($ext_if)

# Rules
block in log all
pass in from <cbsd> to any
pass out all keep state
pass proto tcp to any port ssh
pass inet proto { icmp, igmp }
# pass in proto tcp from any to any port $tcp_ports
# pass in proto udp from any to any port $udp_ports
```

DHCP jail also knows how to update PF table and DNS entries for IPs it leases, so if you use virtual machine, for example, it will be added to PF / DNS via DCHP, not hooks.

You can mount extra paths by creating `template/fstab` in the service directory. For example:
```
/usr/ports /usr/ports nullfs rw 0 0
```
This example will mount /usr/ports from the host to /usr/ports inside jail.

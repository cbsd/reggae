# CBSD integration

Although Reggae could leave CBSD config as it is, it's more suitable to have CBSD aware of Reggae config. Reggae configures hooks, profile and jail skel to run commands on CBSD actions or to make CBSD usable without Reggae.

By default, there is only one hook that Reggae installs and it does two things:
* registeres jail in DNS server
* add's jail IP to PF table (used for granting access and NAT)
DNS registration is done via RNDC and keys, while for /dev/pf access inside jail, special /etc/devfs.rules entry is made but only if /etc/devfs.rules doesn't exist already, so be careful when doing custom configs: you have to add this in devfs:
```
[vnet=8]
add include \$devfsrules_hide_all
add include \$devfsrules_unhide_basic
add include \$devfsrules_unhide_login
add path 'bpf*' unhide
add path 'pf*' unhide
```
If /etc/pf.conf doesn't exist on host, it will be created from a template:
```
# Macros and tables
ext_if = "EGRESS"
table <reggae> { 172.16.0.253 } persist
table <reggae6> { fd10:6c79:8ae5:8b91::2 } persist

# Options
set block-policy drop
set skip on lo0

# Normalization
scrub in all

# NAT (comment out if adding ext_if to bridge)
nat on $ext_if inet from <reggae> to any -> ($ext_if)
nat on $ext_if inet6 from (jails:network) to any -> ($ext_if:0)

# RDR anchors, mostly for port forwarding
rdr-anchor "reggae/*" on $ext_if
# rdr-anchor "service/*" on $ext_if

antispoof quick log for ($ext_if) # comment out if adding ext_if to bridge
anchor "blacklistd/*" in on $ext_if

# Rules
block in log from any to <self>
pass in inet proto udp to any port bootpc
pass in inet6 proto udp from fe80::/10 port dhcpv6-server to fe80::/10 port dhcpv6-client
pass in proto tcp to any port ssh
pass in proto { icmp, igmp, icmp6 }
pass out
```

DHCP jail also knows how to update PF table and DNS entries for IPs it leases, so if you use virtual machine, for example, it will be added to PF / DNS via DCHP, not hooks.

You can mount extra paths by creating `template/fstab` in the service directory. For example:
```
/usr/ports /usr/ports nullfs rw 0 0
```
This example will mount /usr/ports from the host to /usr/ports inside jail.

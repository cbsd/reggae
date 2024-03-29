# DO NOT EDIT THIS FILE. PLEASE USE INSTEAD:
# cbsd bconfig jname=SERVICE
relative_path="1";
jname="SERVICE";
path="CBSD_WORKDIR/jails/SERVICE";
data="CBSD_WORKDIR/jails-data/SERVICE-data";
rcconf="CBSD_WORKDIR/jails-rcconf/rc.conf_SERVICE";

# FQDN for environment
host_hostname="SERVICE.DOMAIN";
# default environment IP
ip4_addr="172.16.0.200";

# start with system boot?
astart="0";

# first NIC hardware address
nic_hwaddr="";

# create from ZFS snapshot?
zfs_snapsrc="";
# run immediately upon creation
runasap="0";
# bind to interface
interface="INTERFACE";
rctl_nice="0"
# Bhyve minimal configuration:
#jname="SERVICE";
# first disk size
imgsize="10g";
# number of vcpu
vm_cpus="1";
# ram amount
vm_ram="1g";
# profile os type
vm_os_type="freebsd";
# vm defaults/setting profile
vm_os_profile="cloud-FreeBSD-zfs-x64-VERSION";
# end of Bhyve minimal configuration

emulator="bhyve";
# disk type - md or zvol
imgtype="zvol";
# efi boot?
vm_efi="uefi";
# source site's for iso
iso_site="https://mirror.bsdstore.ru/cloud/";
# iso image filename
iso_img="FreeBSD-zfs-VERSION-RELEASE-amd64.raw";
# iso image type?
iso_img_type="cloud";
# register ISO as name
register_iso_name="cbsd-cloud-FreeBSD-zfs-VERSION-RELEASE-amd64.raw"
# register ISO as
register_iso_as="cloud-FreeBSD-zfs-x64-VERSION-RELEASE-amd64"
# vm hostbridge
vm_hostbridge="hostbridge";
# additional bhyve flags
bhyve_flags="";
# first disk type
virtio_type="";
# swap size for vm-from-jail
swapsize="";
# path to iso image
vm_iso_path="cloud-FreeBSD-zfs-x64-VERSION-RELEASE-amd64";
# guest fs for vm-from-jail
vm_guestfs="ufs";
# VNC port
vm_vnc_port="0";
# bhyve flags
bhyve_generate_acpi="1";
# bhyve flags
bhyve_wire_memory="0";
# bhyve flags
bhyve_rts_keeps_utc="0";
# bhyve flags
bhyve_force_msi_irq="0";
# bhyve flags
bhyve_x2apic_mode="0";
# bhyve flags
bhyve_mptable_gen="1";
# bhyve flags
bhyve_ignore_msr_acc="0";
# wait for VNC connect when boot from CD
cd_vnc_wait="1";
# VNC resolution
bhyve_vnc_resolution="800x600";
# VNC bind addr
bhyve_vnc_tcp_bind="127.0.0.1";
# vgaconf settings
bhyve_vnc_vgaconf="io";
# first NIC driver
nic_driver="";
# password for VNC
vnc_password='cbsd';
# automatically eject CD when boot from CD and hard-disk is not empty
media_auto_eject="1";
# cpu topology name
vm_cpu_topology="default";
# run via debugger
debug_engine="none";
# emulate xhci
xhci="0";
# use alternative boot firmware
cd_boot_firmware="bhyve";
# jailed bhyve ?
jailed="0";
# custom behavior settings by exit codes
on_poweroff="destroy";
# custom behavior settings by exit codes
on_reboot="restart";
# custom behavior settings by exit codes
on_crash="destroy";
# is cloud image?
is_cloud='1';
# default disk sectorsize
sectorsize='512/4096'
# sound hardware
soundhw="";
soundhw_play="";
soundhw_rec="";
# cloud-init settings
ci_jname='SERVICE';
ci_fqdn='SERVICE.DOMAIN';
ci_template='centos7';
ci_interface='vtnet0';
ci_ip4_addr='DHCP';
ci_nameserver_address='MASTER_IP';
ci_nameserver_search='DOMAIN';
ci_adjust_inteface_helper='0';
ci_user_add='cbsd';
ci_user_pw_user='$6$61V0w0dRFFiEcnm2$o8CLPIdRBVHP13LQizdp12NEGD91RfHSB.c6uKnr9m2m3ZCg7ASeGENMaDt0tffmo5RalKGjWiHCtScCtjYfs/';
ci_user_pw_root='$6$h9pydrjL8JVn6vCO$9kkZInu99CT67.lnESajG4lVB.vGP6uF8otMFI.x9sYWeliDlSn7XS6GT0yTblGbO1Kb4av0ynipvXGIOCAOg1';
ci_user_gecos_provision='';
ci_user_home_cbsd='/home/cbsd';
ci_user_shell_provision='';
ci_user_member_groups_provision='';
ci_user_pubkey_provision='.ssh/authorized_keys';

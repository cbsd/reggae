#!/bin/sh

pkg install -y py36-salt
echo 'salt_master_enable="YES"' >/etc/rc.conf.d/salt_master
service salt_master start

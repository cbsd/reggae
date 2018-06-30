# -*- mode: ansible -*-
# vi: set ft=ansible :

---
- name: SERVICE provisioning
  hosts: SERVICE
  roles:
    - onelove_roles.freebsd-common

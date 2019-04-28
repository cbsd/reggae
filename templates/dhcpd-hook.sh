#!/bin/sh

lockf /var/unbound/conf.d/cbsd.zone.lock /usr/local/bin/reggae-register.sh "$1" "$2" "$3" "$4"

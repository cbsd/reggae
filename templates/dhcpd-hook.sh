#!/bin/sh

lockf /usr/local/etc/nsd/zones/master/cbsd.zone.lock /usr/local/bin/reggae-register.sh "$1" "$2" "$3" "$4"

#!/bin/sh

lockf /tmp/cbsd.zone.lock /usr/local/bin/reggae-register.sh "$1" "$2" "$3" "$4" "$5"

#!/bin/sh

echo -n "Password: " >&2; stty -echo; read passwd; stty echo; echo ${passwd}

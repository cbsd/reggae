.for use in ${USE}
.if ${use} == "letsencrypt"
PRE_SERVICES += letsencrypt https://github.com/mekanix/jail-letsencrypt
.elif ${use} == "ldap"
PRE_SERVICES += ldap https://github.com/mekanix/jail-ldap
.elif ${use} == "postgresql"
PRE_SERVICES += postgresql https://github.com/mekanix/jail-postgresql
.elif ${use} == "mysql"
PRE_SERVICES += mysql https://github.com/mekanix/jail-mysql
.elif ${use} == "wordpress"
USED_SERVICES += wordpress https://github.com/mekanix/jail-wordpress
.elif ${use} == "jabber"
USED_SERVICES += jabber https://github.com/mekanix/jail-jabber
.elif ${use} == "mail"
USED_SERVICES += mail https://github.com/mekanix/jail-mail
.elif ${use} == "opigno"
USED_SERVICES += opigno https://github.com/mekanix/jail-opigno
.elif ${use} == "moodle"
USED_SERVICES += moodle https://github.com/mekanix/jail-moodle
.elif ${use} == "peertube"
USED_SERVICES += peertube https://github.com/mekanix/jail-peertube
.elif ${use} == "nextcloud"
USED_SERVICES += nextcloud https://github.com/mekanix/jail-nextcloud
.elif ${use} == "redis"
USED_SERVICES += redis https://github.com/mekanix/jail-redis
.elif ${use} == "znc"
USED_SERVICES += znc https://github.com/mekanix/jail-znc
.elif ${use} == "coturn"
USED_SERVICES += coturn https://github.com/mekanix/jail-coturn
.elif ${use} == "gitolite"
USED_SERVICES += gitolite https://github.com/mekanix/jail-gitolite
.elif ${use} == "polipo"
USED_SERVICES += polipo https://github.com/mekanix/jail-polipo
.elif ${use} == "nginx"
POST_SERVICES += nginx https://github.com/mekanix/jail-nginx
.endif
.endfor
ALL_SERVICES = ${PRE_SERVICES} ${USED_SERVICES} ${SERVICES} ${POST_SERVICES}

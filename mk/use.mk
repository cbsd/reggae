PRE_SERVICES =
USED_SERVICES =
POST_SERVICES =

USE_PRE_letsencrypt ?= https://github.com/mekanix/jail-letsencrypt
USE_PRE_ldap ?= https://github.com/mekanix/jail-ldap
USE_PRE_postgresql ?= https://github.com/mekanix/jail-postgresql
USE_PRE_mysql ?= https://github.com/mekanix/jail-mysql
USE_PRE_redis ?= https://github.com/mekanix/jail-redis

USE_USED_jabber ?= https://github.com/mekanix/jail-jabber
USE_USED_mail ?= https://github.com/mekanix/jail-mail
USE_USED_webmail ?= https://github.com/mekanix/jail-webmail
USE_USED_moodle ?= https://github.com/mekanix/jail-moodle
USE_USED_opigno ?= https://github.com/mekanix/jail-opigno
USE_USED_wordpress ?= https://github.com/mekanix/jail-wordpress
USE_USED_peertube ?= https://github.com/mekanix/jail-peertube
USE_USED_nextcloud ?= https://github.com/mekanix/jail-peertube
USE_USED_znc ?= https://github.com/mekanix/jail-znc
USE_USED_coturn ?= https://github.com/mekanix/jail-coturn
USE_USED_gitolite ?= https://github.com/mekanix/jail-gitolite
USE_USED_polipo ?= https://github.com/mekanix/jail-polipo

USE_POST_nginx ?= https://github.com/mekanix/jail-nginx

.for use in ${USE}
.if defined(USE_PRE_${use})
PRE_SERVICES += ${use} ${USE_PRE_${use}}
.elif defined(USE_POST_${use})
POST_SERVICES += ${use} ${USE_POST_${use}}
.elif defined(USE_USED_${use})
USED_SERVICES += ${use} ${USE_USED_${use}}
.elif defined(USE_POST_${use})
POST_SERVICES += ${use} ${USE_POST_${use}}
.endif
.endfor

ALL_SERVICES = ${PRE_SERVICES} ${USED_SERVICES} ${SERVICES} ${POST_SERVICES}

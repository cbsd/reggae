CONFIGURED_BACKEND != reggae get-config BACKEND
BACKEND ?= ${CONFIGURED_BACKEND}

.include <${REGGAE_PATH}/mk/${BACKEND}-jail.mk>

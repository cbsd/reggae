.if exists(vars.mk)
.include <vars.mk>
.endif

.if exists(project.mk)
.include <project.mk>
.endif

.if exists(provisioners.mk)
.include <provisioners.mk>
.endif

USE_FREENIT ?= NO

.if ${USE_FREENIT} == "YES"
.include <${REGGAE_PATH}/mk/frameworks/freenit.service.mk>
.endif

.include <${REGGAE_PATH}/mk/common.mk>

.MAIN: up

update:
	@git pull
	@git submodule update --init --recursive

restart: down up

.include <${REGGAE_PATH}/mk/${TYPE}-service.mk>

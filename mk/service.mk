.if exists(vars.mk)
.include <vars.mk>
.endif

.if exists(project.mk)
.include <project.mk>
.endif

.if exists(provisioners.mk)
.include <provisioners.mk>
.endif

.include <${REGGAE_PATH}/mk/common.mk>

.MAIN: up

update:
	@git pull --recurse-submodules

.include <${REGGAE_PATH}/mk/${TYPE}-service.mk>

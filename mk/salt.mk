do-provision:
	@sudo cbsd jexec jname=${SERVICE} pkg install -y py36-salt

do-clean:
	@echo "Remove from master"

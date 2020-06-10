build_lib: up
	@bin/build.sh

publish: build_lib
	@bin/publish.sh

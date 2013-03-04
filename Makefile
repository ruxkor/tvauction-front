test:
	@mocha -R spec --compilers coffee:coffee-script,_coffee:streamline/register

develop: compile-front monitor

compile-front:
	@./scripts/compile_frontend.sh

monitor:
	@./scripts/monitor.sh

.PHONY: test develop monitor compile-front

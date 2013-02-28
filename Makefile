test:
	@mocha -R spec --compilers coffee:coffee-script,_coffee:streamline/register

develop: compile-front nodemon

compile-front:
	@./scripts/compile_frontend.sh

nodemon:
	@DEBUG=* nodemon -e "._coffee" -x _coffee --fibers index._coffee

.PHONY: test develop nodemon compile-front

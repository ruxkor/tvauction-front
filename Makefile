test:
	@mocha -R spec --compilers coffee:coffee-script,_coffee:streamline/register
.PHONY: test

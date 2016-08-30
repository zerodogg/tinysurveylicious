CPANM=$(shell if [ -x "./cpanm" ]; then echo "./cpanm";else echo "cpanm";fi)
WRAPPED_RUN=perl -Ilocal-lib/lib/perl5/ ./server.pl
deps: checkcpanm prepare
prepare: depsinstall
depsinstall:
	$(CPANM) -l local-lib Mojolicious Mojo::SQLite JSON
	[ -e 'tinysurveylicious.conf' ] || cp tinysurveylicious.conf.example tinysurveylicious.conf
checkcpanm:
	@if !which cpanm &>/dev/null && [ ! -e "$$CPANM" ]; then echo "Install cpnminus, or run 'make cpanm' to have the Makefile do it for you"; exit 1;fi
cpanm:
	wget -O ./cpanm "https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm"
	chmod +x ./cpanm
devserver:
	$(WRAPPED_RUN) prefork
production:
	$(WRAPPED_RUN) prefork -m production

S2PAN=    https://s2pan.s2factory.co.jp/
ENV=	  PATH=/usr/pgsql-9.4/bin:/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
MIR=	  --mirror=${S2PAN} --mirror=http://www.cpan.org/ --mirror-only
PERL5LIB= extlib/lib/perl5

all:

test:
	env DWARF_TEST_LEVEL=0 prove -I${PERL5LIB} -rlv t

jenkins:
	env DWARF_TEST_LEVEL=0 JUNIT_OUTPUT_FILE=result.xml prove -rl -I${PERL5LIB} --harness TAP::Harness::JUnit --merge t
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,inc prove -rl -I${PERL5LIB} --merge t
	cover -report html
	cover -report clover

update-extlib: cpanm
	extlib/bin/cpanm -l extlib -v ${MIR} --installdeps .
	chmod -R ug+rw extlib

carton: cpanm
	extlib/bin/cpanm -L extlib -v Carton
	env ${ENV} PERL_CPANM_OPT="${MIR}" PERL5LIB=${PERL5LIB} extlib/bin/carton install --path extlib

cpanm:
	[ -d extlib/bin ] || mkdir -p extlib/bin
	[ -f extlib/bin/cpanm ] || curl -L http://xrl.us/cpanm -o extlib/bin/cpanm
	chmod ug+x extlib/bin/cpanm

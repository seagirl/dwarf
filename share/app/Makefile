S2PAN=    https://s2pan.s2factory.co.jp/
ENV=	  PATH=/usr/pgsql-9.4/bin:/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
MIR=	  --mirror=${S2PAN} --mirror=http://www.cpan.org/ --mirror-only
PERL5LIB= local/lib/perl5

all:

test:
	env DWARF_TEST_LEVEL=0 prove -I${PERL5LIB} -rlv t

jenkins:
	env DWARF_TEST_LEVEL=0 JUNIT_OUTPUT_FILE=result.xml prove -rl -I${PERL5LIB} --harness TAP::Harness::JUnit --merge t
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,inc prove -rl -I${PERL5LIB} --merge t
	cover -report html
	cover -report clover

perl5lib: local/bin/cpanm
	local/bin/cpanm -l local -v ${MIR} --installdeps .
	chmod -R ug+rw local

Net-LibIDN: local/bin/cpanm
	local/bin/cpanm -L local Net::LibIDN --configure-args="--with-libidn-inc=/usr/local/include"

carton: local/bin/cpanm
	local/bin/cpanm -L local -v Carton
	env ${ENV} PERL_CARTON_MIRROR=${S2PAN} PERL5LIB=${PERL5LIB} local/bin/carton

local/bin/cpanm:
	[ -d local/bin ] || mkdir -p local/bin
	[ -f local/bin/cpanm ] || curl -L http://xrl.us/cpanm -o local/bin/cpanm
	chmod ug+rx local/bin/cpanm

use Dwarf::Pragma;
use Dwarf::Util qw/installed/;
use Test::More 0.88;
use FindBin qw($Bin);
use Module::Find;

BEGIN {
	setmoduledirs("$Bin/../../lib");
	for (sort(findallmod("S2Factory"), findallmod("Dwarf"))) {
		if ($_ eq 'Dwarf::Plugin::Cache::Memcached::Fast') {
			next unless installed('Cache::Memcached::Fast');
		}
		if ($_ eq 'Dwarf::Plugin::PHP::Session') {
			next unless installed('PHP::Session');
		}
		use_ok($_);
	}
}

done_testing();

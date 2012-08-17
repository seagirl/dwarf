use Dwarf::Pragma;
use Test::More 0.88;
use FindBin qw($Bin);
use Module::Find;

BEGIN {
	setmoduledirs("$Bin/../lib");
	for (sort(findallmod("S2Factory"), findallmod("Dwarf"), findallmod("App"))) {
		next if $_ eq 'Dwarf::Plugin::Cache::Memcached::Fast';
		next if $_ eq 'Dwarf::Plugin::HTML::Template';
		next if $_ eq 'Dwarf::Plugin::PHP::Session';
		use_ok($_);
	}
}

done_testing();


use Dwarf::Pragma;
use Test::More 0.88;
use FindBin qw($Bin);
use Module::Find;

BEGIN {
	setmoduledirs("$Bin/../lib");
	for (sort(findallmod("S2Factory"), findallmod("Dwarf"), findallmod("App"))) {
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

sub installed {
	my $m = shift;
	my $installed = 1;
	eval " require $m; import $m; ";
	$installed = 0 if $@;
	return $installed;
}
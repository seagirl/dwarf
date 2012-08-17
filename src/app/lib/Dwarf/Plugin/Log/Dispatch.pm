package Dwarf::Plugin::Log::Dispatch;
use strict;
use warnings;
use Dwarf::Util qw/add_method/;
use Log::Dispatch;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $outputs = $conf->{outputs};
	$outputs ||= [
		['File', min_level => 'debug', filename => $c->base_dir . '/dwarf.log'],
		['Screen', min_level => 'warning'],
	];

	my $log = Log::Dispatch->new(outputs => $outputs);

	add_method($c, log => sub {
		my $self = shift;
		return $log;
	});
}

1;

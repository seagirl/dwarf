package Dwarf::Plugin::Now;
use strict;
use warnings;
use DateTime;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	add_method($c, now => sub {
		my $self = shift;
		$self->{__now} ||= DateTime->now(%$conf);
	});
}

1;

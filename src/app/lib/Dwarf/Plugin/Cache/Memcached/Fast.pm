package Dwarf::Plugin::Cache::Memcached::Fast;
use strict;
use warnings;
use Dwarf::Util qw/add_method/;
use Cache::Memcached::Fast;

sub init {
	my ($class, $c, $opt) = @_;
	$opt ||= {};
	$opt->{compress_threshold} ||= 100_000;

	add_method($c, memcached => sub {
		my ($self, $key) = @_;

		$self->{__memcached} ||= do {
			my $conf = $self->config->get('memcached')
				or return;

			Cache::Memcached::Fast->new({
				servers            => [ { address => $conf->{server} } ],
				namespace          => $conf->{namespace},
				compress_threshold => $opt->{compress_threshold},
			});
		};
	});
}

1;

# Local Variables:                    #
# tab-width: 4                        #
# cperl-indent-level: 4               #
# cperl-label-offset: -4              #
# cperl-continued-statement-offset: 4 #
# End:                                #

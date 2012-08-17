package Dwarf::Message;
use strict;
use warnings;

use overload '""' => \&stringfy;

use Dwarf::Accessor {
	rw => [qw/name data/],
};

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		name => 'dwarf_message',
		data => undef,
		@_
	}, $class;
	return $self;
}

sub stringfy {
	my $self = shift;
	return $self->name;
}

1;

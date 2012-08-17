package Dwarf::Error;
use Dwarf::Pragma;

use overload '""' => \&stringfy;

use Dwarf::Accessor {
	rw => [qw/autoflush messages/],
};

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		autoflush => 0,
		messages  => [],
		@_
	}, $class;
	return $self;
}

sub message { $_[0]->messages->[0] }
sub body    { $_[0]->message ? $_[0]->message->body : [] }

sub throw {
	my $self = shift;

	my $m = Dwarf::Error::Message->new;
	$m->body([@_]);

	if ($self->autoflush) {
		$self->{messages} = [$m];
		$self->flush;
	} else {
		push @{ $self->{messages} }, $m;
	}

	return $self;
}

sub flush {
	my $self = shift;
	if (@{ $self->messages }) {
		die $self;
	}
}

sub stringfy {
	my $self = shift;
	return join "\n", @{ $self->messages };
}

package Dwarf::Error::Message;
use strict;
use warnings;

use overload '""' => \&stringfy;

use Dwarf::Accessor {
	rw => [qw/body/],
};

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		body => [],
		@_
	}, $class;
	return $self;
}

sub stringfy {
	my $self = shift;
	my $body = $self->body;
	if (ref $body eq 'ARRAY') {
		$body = join ', ', @{ $body };
	}
	return '[Error] ' . $body;
}


1;

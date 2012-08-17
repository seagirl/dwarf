package Dwarf::Config;
use Dwarf::Pragma;

use Dwarf::Accessor {
	ro => [qw/context/]
};

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;	
	$self->init;
	return $self;
}

sub c { shift->context }

sub init {
	my $self = shift;
	$self->set($self->setup);
}

sub setup { return () }

sub get {
	my ($self, $key) = @_;
	return $self->{$key};
}

sub set {
	my $self = shift;
	my $args = { @_ };

	while (my ($key, $value) = each %$args) {
		$self->{$key} = $value;
	}
}

1;

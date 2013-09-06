package Dwarf::Config;
use Dwarf::Pragma;
use Dwarf::Util qw/installed dwarf_log/;

use Dwarf::Accessor {
	ro => [qw/context/]
};

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	dwarf_log 'new Config';
	$self->init;
	return $self;
}

sub DESTROY {
	my $self = shift;
	dwarf_log 'DESTROY Config';
	delete $self->{context};
}

sub c { shift->context }

sub init {
	my $self = shift;
	$self->set($self->setup);
}

sub setup { return () }

sub get {
	my ($self, $key) = @_;

	# Data::Path サポート
	if (installed('Data::Path')) {
		if ($key =~ /\//) {
			my $hpath = Data::Path->new($self);
			return $hpath->get($key);
		}
	}

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

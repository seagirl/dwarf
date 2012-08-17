package Dwarf::Response;
use Dwarf::Pragma;

our $BACKEND;

do {
	if (eval { require Plack::Response }) {
		$BACKEND = 'Plack::Response';
	} elsif (eval { require Dwarf::Response::Backend }) {
		$BACKEND = 'Dwarf::Response::Backend';
	} else {
		die "Unable to locate Plack::Response or Dwarf::Response::Backend in INC";
	}
};

sub new {
	my $class = shift;
	return $BACKEND->new(@_);
}

1;

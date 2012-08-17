package Dwarf::Request;
use Dwarf::Pragma;

our $BACKEND;

do {
	if (eval { require Plack::Request }) {
		$BACKEND = 'Plack::Request';
	} elsif (eval { require Dwarf::Request::Backend }) {
		$BACKEND = 'Dwarf::Request::Backend';
	} else {
		die "Unable to locate Plack::Request or Dwarf::Request::Backend in INC";
	}
};

sub new {
	my $class = shift;
	return $BACKEND->new(@_);
}

1;

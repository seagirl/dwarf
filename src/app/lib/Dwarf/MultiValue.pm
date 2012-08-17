package Dwarf::MultiValue;
use Dwarf::Pragma;

our $BACKEND;

do {
	if (eval { require Plack::MultiValue }) {
		$BACKEND = 'Plack::MultiValue';
	} elsif (eval { require Dwarf::MultiValue::Backend }) {
		$BACKEND = 'Dwarf::MultiValue::Backend';
	} else {
		die "Unable to locate Plack::MultiValue or Dwarf::MultiValue::Backend in INC";
	}
};

sub new {
	my $class = shift;
	return $BACKEND->new(@_);
}

1;

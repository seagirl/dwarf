package Dwarf::TempBuffer;
use Dwarf::Pragma;

our $BACKEND;

do {
	if (eval { require Plack::TempBuffer }) {
		$BACKEND = 'Plack::TempBuffer';
	} elsif (eval { require Dwarf::TempBuffer::Backend }) {
		$BACKEND = 'Dwarf::TempBuffer::Backend';
	} else {
		die "Unable to locate Plack::TempBuffer or Dwarf::TempBuffer::Backend in INC";
	}
};

sub new {
	my $class = shift;
	return $BACKEND->new(@_);
}

1;

package Dwarf::Validator::File;
use FormValidator::Lite::Constraint;

file_rule 'FILE_NOT_NULL' => sub {
	return 0 if not defined($_);
	return 0 if $_ eq "";
	return 0 if ref($_) eq 'ARRAY' && @$_ == 0;
	return 1;
};

file_rule 'FILE_EXT' => sub {
    Carp::croak('missing args. usage: ["FILE_MIME", "text/plain"]') unless @_;
    my $expected = $_[0];
    my $ext = '';
    if ($_->{upload}->filename =~ /\.(.+)$/) {
		$ext = lc $1;
	}
    return $ext =~ /^$expected$/;
};

1;

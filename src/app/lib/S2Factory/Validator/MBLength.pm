package S2Factory::Validator::MBLength;
use Dwarf::Pragma;
use FormValidator::Lite::Constraint;
use Encode qw(decode_utf8);

rule 'MB_LENGTH' => sub {
	my $len = length(decode_utf8($_));
	my $min = shift;
	my $max = shift || $min;
	Carp::croak("missing \$min") unless defined($min);
	return ($min <= $len and $len <= $max);
};

rule 'MB_MULTILINE_LENGTH' => sub {
	my $s = $_;
	$s =~ s/\x0D\x0A|\x0D|\x0A/\n/g;

	my @a = split '\n', $s;
	my ($min, $min_line, $max, $max_line) = @_;
	$max ||= $min;
	$max_line ||= $min_line;

	Carp::croak("missing \$min") unless defined($min);
	Carp::croak("missing \$min_line") unless defined($min_line);

	return 0 if @a < $min_line or $max_line < @a;

	for my $_ (@a) {
		my $len = length(decode_utf8($_));
		return 0 if $len < $min or $max < $len;
	}

	return 1;
};

1;
# Local Variables:                    #
# tab-width: 4                        #
# cperl-indent-level: 4               #
# cperl-label-offset: -4              #
# cperl-continued-statement-offset: 4 #
# End:                                #

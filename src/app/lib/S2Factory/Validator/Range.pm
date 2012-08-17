package S2Factory::Validator::Range;
use Dwarf::Pragma;
use FormValidator::Lite::Constraint;
use Scalar::Util qw/looks_like_number/;

rule 'RANGE' => sub {
	my ($min, $max) = @_;

	my $value = $_;

	if (defined $value and looks_like_number($value)) {
		if (defined $min and defined $max) {
			return ($value >= $min) && ($value <= $max);
		}
		elsif (defined $min) {
			return ($value >= $min);
		}
		elsif (defined $max) {
			return ($value <= $max);
		}

		die "missing min and max";
	}

	return 1;
};

1;

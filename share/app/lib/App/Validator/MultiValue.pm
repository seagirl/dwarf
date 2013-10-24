package App::Validator::MultiValue;
use FormValidator::Lite::Constraint;
use S2Factory::Validator;
use Scalar::Util qw/looks_like_number/;

rule 'ARRAY' => sub {
	my $value = $_;
	my $type = $_[0];
	my $delimiter = $_[1] || ',';

	if ($delimiter eq '\n') {
		$value =~ s/\r\n/\n/g;
		$value =~ s/\r/\n/g;
	}

	my $result = 1;
	for (split $delimiter, $value) {
		if ($type eq 'NUMBER') {
			unless (looks_like_number($_)) {
				$result = 0;
				last;
			}
		} elsif ($type eq 'UINT') {
			unless ($_ =~ /\A[0-9]+\z/) {
				$result = 0;
				last;
			}
		} elsif ($type eq 'INT') {
			unless ($_ =~ /\A[+\-]?[0-9]+\z/) {
				$result = 0;
				last;
			}
		}
	}

	return $result;
};

rule 'ARRAY_2D' => sub {
	my $value = $_;
	my $type = $_[0];
	my $delimiter1 = $_[1] || ',';
	my $delimiter2 = $_[2] || '\n';

	my $result = 1;
	for my $line (split $delimiter2, $value) {
		if ($delimiter2 eq '\n') {
			$value =~ s/\r\n/\n/g;
			$value =~ s/\r/\n/g;
		}

		for (split $delimiter1, $line) {
			if ($type eq 'NUMBER') {
				unless (looks_like_number($_)) {
					$result = 0;
					last;
				}
			} elsif ($type eq 'UINT') {
				unless ($_ =~ /\A[0-9]+\z/) {
					$result = 0;
					last;
				}
			} elsif ($type eq 'INT') {
				unless ($_ =~ /\A[+\-]?[0-9]+\z/) {
					$result = 0;
					last;
				}
			}
		}
	}

	return $result;
};

1;

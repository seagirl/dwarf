package App::Validator::Number;
use FormValidator::Lite::Constraint;
use Scalar::Util qw/looks_like_number/;

rule 'NUMBER' => sub {
	my $value = $_;
	return 1 unless defined $value;
	return looks_like_number $value;
	1;
};

1;

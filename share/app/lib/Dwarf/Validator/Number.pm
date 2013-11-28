package Dwarf::Validator::Number;
use FormValidator::Lite::Constraint;
use Scalar::Util qw/looks_like_number/;

rule NUMBER => sub {
	my $value = $_;
	return 1 unless defined $value;
	return looks_like_number $value;
};

rule BETWEEN => sub {
    $_[0] <= $_ && $_ <= $_[1];
};

rule LESS_THAN => sub {
    $_ < $_[0];
};

rule LESS_EQUAL => sub {
    $_ <= $_[0];
};

rule MORE_THAN => sub {
    $_[0] < $_;
};

rule MORE_EQUAL => sub {
    $_[0] <= $_;
};

1;

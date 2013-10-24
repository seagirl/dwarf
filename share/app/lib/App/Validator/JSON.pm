package App::Validator::MultiValue;
use FormValidator::Lite::Constraint;
use JSON;

rule 'JSON' => sub {
	my $value = $_;
	return 1 unless defined $value;
	my $data = eval { decode_json $value };
	if ($@) {
		warn $@;
		warn $value;
		return 0;
	}
	return 1;
};

1;

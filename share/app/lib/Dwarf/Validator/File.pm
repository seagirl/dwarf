package Dwarf::Validator::File;
use FormValidator::Lite::Constraint;

file_rule 'FILE_NOT_NULL' => sub {
	return 0 if not defined($_);
	return 0 if $_ eq "";
	return 0 if ref($_) eq 'ARRAY' && @$_ == 0;
	return 1;
};

1;

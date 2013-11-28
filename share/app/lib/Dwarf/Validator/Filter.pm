package Dwarf::Validator::Filter;
use Dwarf::Pragma;
use Encode;
use FormValidator::Lite::Constraint::Default;

$FormValidator::Lite::Constraint::Default::Filters->{'decode_utf8'} = sub {
	my $value = shift;
	return $value unless $value;
	$value = decode_utf8($value);
	$value;
};

$FormValidator::Lite::Constraint::Default::Filters->{'normalize_line_endings'} = sub {
	my $value = shift;
	return $value unless $value;
	$value =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$value;
};

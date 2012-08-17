package App::Validator::ISO639;
use Dwarf::Pragma;
use FormValidator::Lite::Constraint;
use Encode qw(decode_utf8);

rule 'ISO639-1' => sub {
	my $str = $_;
	$str =~ /^(en|ja|zh)$/;
};

1;

use Dwarf::Pragma;
use JSON;
use Test::More 0.88;

subtest "boolean" => sub {
	ok true;
	ok !false;
	ok (1 == 1);
	ok !(1 == 0);

	my $json = JSON->new->convert_blessed;
	my $encoded = $json->encode({ false => ( 0 == 1 ), true => ( 1 == 1 ) });
	is $encoded, '{"false":false,"true":true}';
};

done_testing();

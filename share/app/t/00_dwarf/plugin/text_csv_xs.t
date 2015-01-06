use Dwarf::Pragma;
use Dwarf;
use Test::More;
use Test::Requires 'Text::CSV_XS';

my $c = Dwarf->new();

$c->load_plugin("Text::CSV_XS" => {});

ok $c->can('read_csv');
ok $c->can('decode_csv');
ok $c->can('encode_csv');

my @data = (
	['日本語', 'data', 'ああああ'],
	['日本語', 'data', 'ああああ'],
	['日本語', 'data', 'ああああ'],
);

my $csv = $c->encode_csv(@data);
my @data2 = $c->decode_csv($csv);

is_deeply(\@data, \@data2);

done_testing;

use strict;
use warnings;
use utf8;
use Test::Base::Less;
use Dwarf::Validator;
use Dwarf::Request;
use Hash::MultiValue;

filters {
	query    => [qw/eval/],
	rule     => [qw/eval/],
	expected => [qw/eval/],
};

for my $block (blocks) {
	my $q = Dwarf::Request->new({ env => {} });
	$q->env->{'dwarf.request.merged'} = Hash::MultiValue->from_mixed($block->query);

	my $v = Dwarf::Validator->new($q);
	$v->check(
		$block->rule
	);

	my @expected = $block->expected;
	while (my ($key, $val) = splice(@expected, 0, 2)) {
		is($v->is_error($key), $val, $block->name);
	}
}

done_testing;

__END__

=== NOT_NULL
--- query: { hoge => 1, zero => 0, blank => "", undef => undef, multi => 1, multi => undef, }
--- rule
(
	hoge      => [qw/NOT_NULL/],
	zero      => [qw/NOT_NULL/],
	blank     => [qw/NOT_NULL/],
	undef     => [qw/NOT_NULL/],
	missing   => [qw/NOT_NULL/],
	multi     => [qw/NOT_NULL/],
	'array[]' => [qw/NOT_NULL/],
);
--- expected
(
	hoge      => 0,
	zero      => 0,
	blank     => 0,
	undef     => 1,
	missing   => 1,
	multi     => 1,
	'array[]' => 1,
)

=== REQUIRED
--- query: { hoge => 1, zero => 0, blank => "", undef => undef }
--- rule
(
	hoge    => [qw/REQUIRED/],
	zero    => [qw/REQUIRED/],
	blank   => [qw/REQUIRED/],
	undef   => [qw/REQUIRED/],
	missing => [qw/REQUIRED/],
);
--- expected
(
	hoge    => 0,
	zero    => 0,
	blank   => 0,
	undef   => 1,
	missing => 1,
)

=== NOT_BLANK
--- query: { hoge => 1, zero => 0, blank => "", undef => undef }
--- rule
(
	hoge    => [qw/NOT_BLANK/],
	zero    => [qw/NOT_BLANK/],
	blank   => [qw/NOT_BLANK/],
	undef   => [qw/NOT_BLANK/],
	missing => [qw/NOT_BLANK/],
);
--- expected
(
	hoge    => 0,
	zero    => 0,
	blank   => 1,
	undef   => 1,
	missing => 1,
)

=== INT
--- query: { hoge => '1', fuga => '-1', hoga => 'ascii', foo => "1\n" }
--- rule
(
	hoge => [qw/INT/],
	fuga => [qw/INT/],
	hoga => [qw/INT/],
	foo  => [qw/INT/],
)
--- expected
(
	hoge => 0,
	fuga => 0,
	hoga => 1,
	foo  => 1,
)

=== UINT
--- query: { hoge => '1', fuga => '-1', hoga => 'ascii', foo => "1\n" }
--- rule
(
	hoge => [qw/UINT/],
	fuga => [qw/UINT/],
	hoga => [qw/UINT/],
	foo  => [qw/UINT/],
)
--- expected
(
	hoge => 0,
	fuga => 1,
	hoga => 1,
	foo  => 1,
)

=== NUMBER
--- query: { hoge => '1.0', fuga => '-1.1', hoga => 'ascii' }
--- rule
(
	hoge => [qw/NUMBER/],
	fuga => [qw/NUMBER/],
	hoga => [qw/NUMBER/],
	foo  => [qw/NUMBER/],
)
--- expected
(
	hoge => 0,
	fuga => 0,
	hoga => 1,
)

=== EQUAL
--- query: { 'z1' => 'foo', 'z2' => 'foo' }
--- rule
(
	'z1' => [[EQUAL => 'foo']],
	'z2' => [[EQUAL => 'bar']],
)
--- expected
(
	z1 => 0,
	z2 => 1,
)

=== BETWEEN
--- query: { num => 5 }
--- rule
(
	num => [
		[BETWEEN => 1, 10],
	],
)
--- expected
(
	num => 0,
)

=== BETWEEN
--- query: { num => 5 }
--- rule
(
	num => [
		[BETWEEN => 6, 10],
	],
)
--- expected
(
	num => 1,
)

=== BETWEEN
--- query: { num => 5 }
--- rule
(
	num => [
		[BETWEEN => 1, 4],
	],
)
--- expected
(
	num => 1,
)

=== LESS_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_THAN => 5],
	],
)
--- expected
(
	num => 1,
)

=== LESS_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_THAN => 6],
	],
)
--- expected
(
	num => 0,
)

=== LESS_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_EQUAL => 5],
	],
)
--- expected
(
	num => 0,
)

=== LESS_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_EQUAL => 4],
	],
)
--- expected
(
	num => 1,
)

=== MORE_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_THAN => 5],
	],
)
--- expected
(
	num => 1,
)

=== MORE_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_THAN => 4],
	],
)
--- expected
(
	num => 0,
)

=== MORE_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_EQUAL => 5],
	],
)
--- expected
(
	num => 0,
)

=== MORE_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_THAN => 6],
	],
)
--- expected
(
	num => 1,
)

=== ASCII
--- query: { hoge => 'abcdefg', fuga => 'あbcdefg' }
--- rule
(
	hoge => [qw/ASCII/],
	fuga => [qw/ASCII/],
)
--- expected
(
	hoge => 0,
	fuga => 1,
)

=== LENGTH
--- query: { 'z1' => 'foo', 'z2' => 'foo', 'z3' => 'foo', 'x1' => 'foo', x2 => 'foo', x3 => 'foo' }
--- rule
(
	z1 => [['LENGTH', '2']],
	z2 => [['LENGTH', '3']],
	z3 => [['LENGTH', '4']],
	x1 => [['LENGTH', '2', '2']],
	x2 => [['LENGTH', '2', '3']],
	x3 => [['LENGTH', '2', '4']],
)
--- expected
(
	z1 => 1,
	z2 => 0,
	z3 => 1,
	x1 => 1,
	x2 => 0,
	x3 => 0,
)

=== DATE
--- query: { y => 2009, m => 2, d => 30 }
--- rule
(
	{date => [qw/y m d/]} => ['DATE'],
)
--- expected
(
	date => 1,
)

=== DATE
--- query: { y => 2009, m => 2, d => 28 }
--- rule
(
	{date => [qw/y m d/]} => ['DATE'],
)
--- expected
(
	date => 0,
)

=== DATE-NOT_NULL
--- query: {  }
--- rule
(
	{date => [qw/y m d/]} => ['DATE', 'NOT_NULL'],
)
--- expected
(
	date => 1,
)

=== DATE
--- query: { date => '2009-02-28' }
--- rule
(
	date => ['DATE'],
)
--- expected
(
	date => 0,
)

=== DATE with blank arg.
--- query: { y => '', m => '', d => ''}
--- rule
(
	{date => [qw/y m d/]} => ['DATE'],
)
--- expected
(
	date => 1,
)

=== TIME should success
--- query: { h => 12, m => 0, s => 30 }
--- rule
(
	{date => [qw/h m s/]} => ['TIME'],
)
--- expected
(
	date => 0,
)
 
=== TIME should fail
--- query: { h => 24, m => 0, s => 0 }
--- rule
(
	{date => [qw/h m s/]} => ['TIME'],
)
--- expected
(
	date => 1,
)

=== TIME-NOT_NULL
--- query: {  }
--- rule
(
	{date => [qw/h m s/]} => ['TIME', 'NOT_NULL'],
)
--- expected
(
	date => 1,
)

=== TIME
--- query: { time => '12:30:00' }
--- rule
(
	date => ['TIME'],
)
--- expected
(
	date => 0,
)

=== TIME should not warn with ''
--- query: { h => '', m => '', s => ''}
--- rule
(
	{date => [qw/h m s/]} => ['TIME'],
)
--- expected
(
	date => 1,
)

=== HTTP_URL
--- query: { p1 => 'http://example.com/', p2 => 'foobar', }
--- rule
(
	p1 => ['HTTP_URL'],
	p2 => ['HTTP_URL'],
);
--- expected
(
	p1 => 0,
	p2 => 1,
)

=== EMAIL
--- query: { p1 => 'http://example.com/', p2 => 'foobar@example.com', p3 => 'foo..bar.@example.com' }
--- rule
(
	p1 => ['EMAIL'],
	p2 => ['EMAIL'],
	p3 => ['EMAIL'],
);
--- expected
(
	p1 => 1,
	p2 => 0,
	p3 => 1,
)

=== EMAIL_LOOSE
--- query: { p1 => 'http://example.com/', p2 => 'foobar@example.com', p3 => 'foo..bar.@example.com' }
--- rule
(
	p1 => ['EMAIL_LOOSE'],
	p2 => ['EMAIL_LOOSE'],
	p3 => ['EMAIL_LOOSE'],
);
--- expected
(
	p1 => 1,
	p2 => 0,
	p3 => 0,
)

=== HIRAGANA
--- query: { hoge => 'ひらがなひらがな', fuga => 'カタカナ', haga => 'asciii', hoga => 'ひらがなと  すぺえす'}
--- rule
(
	hoge => [qw/HIRAGANA/],
	fuga => [qw/HIRAGANA/],
	hoga => [qw/HIRAGANA/],
	haga => [qw/HIRAGANA/],
);
--- expected
(
	hoge => 0,
	fuga => 1,
	hoga => 0,
	haga => 1,
)

=== KATAKANA
--- query: { 'p1' => 'ひらがなひらがな', 'p2' => 'カタカナ', 'p3' => 'カタカナ ト スペエス', p4 => 'ascii'}
--- rule
(
	p1 => [qw/KATAKANA/],
	p2 => [qw/KATAKANA/],
	p3 => [qw/KATAKANA/],
	p4 => [qw/KATAKANA/],
);
--- expected
(
	p1 => 1,
	p2 => 0,
	p3 => 0,
	p4 => 1,
)

=== JTEL
--- query: { 'p1' => '666-666-6666', 'p2' => '03-5555-5555'}
--- rule
(
	p1 => [qw/JTEL/],
	p2 => [qw/JTEL/],
);
--- expected
(
	p1 => 1,
	p2 => 0,
)

=== JZIP
--- query: { 'p1' => '155-0044', 'p2' => '03-5555-5555'}
--- rule
(
	p1 => [qw/JZIP/],
	p2 => [qw/JZIP/],
);
--- expected
(
	p1 => 0,
	p2 => 1,
)

=== DUPLICATION
--- query: { 'z1' => 'foo', 'z2' => 'foo', 'z3' => 'fob' }
--- rule
(
	{x1 => [qw/z1 z2/]} => ['DUPLICATION'],
	{x2 => [qw/z2 z3/]} => ['DUPLICATION'],
	{x3 => [qw/z1 z3/]} => ['DUPLICATION'],
)
--- expected
(
	x1 => 0,
	x2 => 1,
	x3 => 1,
)

=== REGEX
--- query: { 'z1' => 'ba3', 'z2' => 'bao' }
--- rule
(
	z1 => [['REGEX',  '^ba[0-9]$']],
	z2 => [['REGEXP', '^ba[0-9]$']],
)
--- expected
(
	z1 => 0,
	z2 => 1,
)

=== CHOICE
--- query: { 'z1' => 'foo', 'z2' => 'quux' }
--- rule
(
	z1 => [ ['CHOICE' => [qw/foo bar baz/]] ],
	z2 => [ ['IN'     => [qw/foo bar baz/]] ],
)
--- expected
(
	z1 => 0,
	z2 => 1,
)

=== NOT_IN
--- query: { 'z1' => 'foo', 'z2' => 'quux', z3 => 'hoge', z4 => 'eee' }
--- rule
(
	z1 => [ ['NOT_IN', [qw/foo bar baz/]] ],
	z2 => [ ['NOT_IN', [qw/foo bar baz/]] ],
	z3 => [ ['NOT_IN', []] ],
	z4 => [ ['NOT_IN'] ],
)
--- expected
(
	z1 => 1,
	z2 => 0,
	z3 => 0,
	z4 => 0,
)

=== MATCH
--- query: { 'z1' => 'ba3', 'z2' => 'bao' }
--- rule
(
	z1 => [[MATCH => sub { $_[0] eq 'ba3' } ]],
)
--- expected
(
	z1 => 0,
)

=== FILTER
--- query: { 'foo' => ' 123 ', bar => 'one' }
--- rule
(
	foo => [[FILTER => 'TRIM'], 'INT'],
	bar => [[FILTER => sub { my $v = shift; $v =~ s/one/1/; $v } ], 'INT'],
)
--- expected
(
	foo => 0,
	bar => 0,
)

=== FILTER (TRIM/DEFAULT)
--- query: { 'foo' => ' 123 ' }
--- rule
(
	foo => ['TRIM', 'INT'],
	bar => [[DEFAULT => 1], 'INT'],
)
--- expected
(
	foo => 0,
	bar => 0,
)

=== FILTER (with multiple values)
--- query: { 'foo' => [' 0 ', ' 123 ', ' 234 '], 'bar' => [qw(one one)] }
--- rule
(
	foo => [[FILTER => 'trim'], 'INT'],
	bar => [[FILTER => sub { my $v = shift; $v =~ s/one/1/; $v } ], 'INT'],
)
--- expected
(
	foo => 0,
	bar => 0,
)

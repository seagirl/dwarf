use Dwarf::Pragma;
use Test::More 0.88;

BEGIN {
	require_ok 'Dwarf';
	require_ok 'DBD::Pg';
	require_ok 'JSON';
	require_ok 'HTML::FillInForm::Lite';
	require_ok 'HTTP::Session';
	require_ok 'HTTP::Session::Store::DBI';
	require_ok 'Log::Dispatch';
	require_ok 'Teng';
	require_ok 'Text::Xslate';
	require_ok 'XML::Simple';
}

done_testing();

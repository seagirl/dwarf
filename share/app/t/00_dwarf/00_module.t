use Dwarf::Pragma;
use Test::More 0.88;

BEGIN {
	require_ok 'boolean';
	require_ok 'AnyEvent';
	require_ok 'AnyEvent::HTTP';
	require_ok 'Class::Method::Modifiers';
	require_ok 'Data::Path';
	require_ok 'Data::Section::Simple';
	require_ok 'DateTime::Format::HTTP';
	require_ok 'DateTime::Format::Pg';
	require_ok 'DBI';
	require_ok 'Exporter::Lite';
	require_ok 'File::Basename';
	require_ok 'File::Copy';
	require_ok 'File::Path';
	require_ok 'File::Spec';
	require_ok 'File::Temp';
	require_ok 'FormValidator::Lite';
	require_ok 'LWP::UserAgent';
	require_ok 'LWP::Protocol::https';
	require_ok 'Module::Find';
	require_ok 'Plack';
	require_ok 'Plack::Handler::CLI';
	require_ok 'Router::Simple';
	require_ok 'Scalar::Util';
	require_ok 'String::CamelCase';
	require_ok 'UNIVERSAL::require';
}

done_testing();

package App::Controller::ApiBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::APIBase';
use Dwarf::DSL;
use App::Constant;

sub will_dispatch {
	load_plugins(
		'JSON'               => { pretty => 1 },
#		'XML::Simple'        => {
#			NoAttr        => 1,
#			RootName      => '<APP_NAME>',
#			KeyAttr       => [],
#			SuppressEmpty => '',
#			XMLDecl       => '<?xml version="1.0" encoding="utf-8"?>'
#		},
#		'Error' => {
#			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
#			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
#			NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
#			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
#			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
#			ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
#		},
		'CGI::Session' => {
			dbh           => db('master')->dbh,
			table         => SES_TABLE,
			session_key   => SES_KEY,
			cookie_path   => '/',
#			cookie_secure => TRUE,
			param_name    => 'session_id',
			on_init       => sub {},
		},
	);

	# デフォルトは JSON。XML にしたい場合は type を XML にする。
	# type('application/xml; charset=utf-8');
}

1;

package App::Controller::ApiBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::APIBase';
use Dwarf::DSL;
use App::Constant;

sub will_dispatch {
	load_plugins(
		'JSON'               => {
			pretty          => 1,
			convert_blessed => 1,
		},
#		'XML::Simple'        => {
#			NoAttr        => 1,
#			RootName      => 'test',
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
		'HTTP::Session' => {
			session_key         => conf('/session/state/name'),
			session_table       => conf('/session/store/table'),
			session_expires     => 60 * 60 * 24,
			session_clean_thres => 1,
			param_name          => 'session_id',
			cookie_path         => '/',
			cookie_secure       => false,
		},
	);

	# デフォルトは JSON。XML にしたい場合は type を XML にする。
	# type('application/xml; charset=utf-8');
}

1;

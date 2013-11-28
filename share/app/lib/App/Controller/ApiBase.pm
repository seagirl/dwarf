package App::Controller::ApiBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::APIBase';
use Dwarf::DSL;
use App::Constant;
use Class::Method::Modifiers;

sub will_dispatch {
	load_plugins(
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			INVALID_SESSION => sub { shift->throw(1003, sprintf("illegal session.")) },
			NEED_TO_LOGIN   => sub { shift->throw(1004, sprintf("You must login.")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(9999, sprintf("%s", $_[0] || "Unknown Error.")) },
		},

		'HTTP::Session' => {
			session_key         => conf('/session/state/name'),
			session_table       => conf('/session/store/table'),
			session_expires     => 60 * 60 * 24 * 21,
			session_clean_thres => 1,
			param_name          => 'session_id',
			cookie_path         => '/',
			cookie_domain       => undef,
			cookie_expires      => 60 * 60 * 24 * 21,
			cookie_secure       => false,
		},

		'JSON' => {
			pretty          => 1,
			convert_blessed => 1,
		},
	);
}

after 'will_render' => sub {
	my ($self, $c, $data) = @_;

	$data->{result} = 'success';

	if ($data->{error_code}) {
		$data->{result} = "fail";
	}
};

1;

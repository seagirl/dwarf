package App::Controller::WebBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::HTMLBase';
use Dwarf::DSL;
use App::Constant;

sub init_plugins {
	load_plugins(
		'Text::Xslate' => {
			path      => [ c->base_dir . '/tmpl' ],
			cache_dir => c->base_dir . '/.xslate_cache',
		},
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
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
			cookie_secure       => conf('ssl') ? true : false,
		},
	);
}

sub will_dispatch {
	
}

# テンプレートに渡す共通の値を定義することなどに使う
# 例）ヘッダなど
# sub will_render {
#	my ($self, $c, $data) = @_;
# }

# 500 系のエラー
sub receive_server_error {
	my ($self, $c, $error) = @_;
	print STDERR sprintf "[Server Error] %s\n", $error;
	$self->{server_error_template}    ||= '500.html';
	$self->{server_error_vars} ||= {};
	return $c->render($self->server_error_template, $self->server_error_vars);
}

1;


package App::Controller::ApiBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::APIBase';
use App::Constant;

sub before_dispatch {
	my ($self, $c) = @_;

	$c->load_plugins(
		'JSON'               => { pretty => 1 },
#		'XML::Simple'        => {
#			NoAttr        => 1,
#			RootName      => '<APP_NAME>',
#			KeyAttr       => [],
#			SuppressEmpty => '',
#			XMLDecl       => '<?xml version="1.0" encoding="utf-8"?>'
#		},
		'CGI::Session' => {
			dbh           => $self->db('master')->dbh,
			table         => SES_TABLE,
			session_key   => SES_KEY,
			cookie_path   => '/',
#			cookie_secure => TRUE,
			param_name    => 'session_id',
			on_init       => sub {},
		},
	);

	# デフォルトは JSON。XML にしたい場合はコメントアウトして下さい。
	# $self->type('application/xml; charset=utf-8');
}

1;

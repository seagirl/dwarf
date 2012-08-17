package App::Controller::ApiBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::ApiBase';
use Class::Method::Mofifiers;
use App::Constant;

before init => sub {
	my ($self, $c) = @_;

	$c->load_plugins(
		'JSON'               => { pretty => 1 },
		'XML::Simple'        => {
			NoAttr        => 1,
			RootName      => '<APP_NAME>',
			KeyAttr       => [],
			SuppressEmpty => '',
			XMLDecl       => '<?xml version="1.0" encoding="utf-8"?>'
		},
#		'CGI::Session' => {
#			dbh           => $self->db('master')->dbh,
#			table         => SES_TABLE,
#			session_key   => SES_KEY,
#			cookie_path   => '/',
#			cookie_secure => TRUE,
#			param_name    => 'session_id',
#			on_init       => sub {},
#		},
	);

	$self->type('application/json; charset=utf-8');
};

1;

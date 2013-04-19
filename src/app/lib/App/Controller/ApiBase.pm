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
#			RootName      => 'tagle',
#			KeyAttr       => [],
#			SuppressEmpty => '',
#			XMLDecl       => '<?xml version="1.0" encoding="utf-8"?>'
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

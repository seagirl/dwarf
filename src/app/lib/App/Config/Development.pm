package App::Config::Development;
use Dwarf::Pragma;
use parent 'Dwarf::Config';

sub setup {
	my $self = shift;
	return (
		db => {
			master => {
				dsn      => 'dbi:Pg:dbname=<APP_NAME>',
				username => 'www',
				password => '',
				opts     => { pg_enable_utf8 => 1 },
			},
		},
		ssl => 1,
		url => {
			base     => 'http://<APP_NAME>.s2factory.co.jp',
			ssl_base => 'https://<APP_NAME>.s2factory.co.jp',
		},
		dir => {
		},
		filestore => {
			private_dir => $self->c->base_dir . "/../data",
			public_dir  => $self->c->base_dir . "/../htdocs/data",
			public_uri  => "/data",
		},
		app => {
			facebook => {
				id     => '',
				secret => '',
			},
			twitter  => {
				id     => '',
				secret => '',
			}
		},
	);
}

1;


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
		session => {
			store => {
				table => 'sessions',
			},
			state => {
				name  => '<APP_NAME>_sid',
			},
		},
		ssl => 1,
		url => {
			base     => 'http://<APP_NAME>.s2factory.co.jp',
			ssl_base => 'https://<APP_NAME>.s2factory.co.jp',
			filestore => {
				public  => "/data",
			},
		},
		dir => {
			filestore => {
				private => $self->c->base_dir . "/../data",
				public  => $self->c->base_dir . "/../htdocs/data",
			},
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


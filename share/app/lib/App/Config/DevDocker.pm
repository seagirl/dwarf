package App::Config::DevDocker;
use Dwarf::Pragma;
use parent 'Dwarf::Config';

sub setup {
	my $self = shift;
	return (
		ssl => 0,
		url => {
			base     => 'http://localhost:5000',
			ssl_base => 'https://localhost:5000',
		},
		db => {
			master => {
				dsn      => 'dbi:Pg:dbname=postgres; host=db; port=5432',
				username => 'postgres',
				password => 'postgres',
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
		filestore => {
			private => {
				dir => $self->c->base_dir . "/filestore",
				uri => "/filestore",
			},
			public  => {
				dir => $self->c->base_dir . "/../htdocs/filestore",
				uri => "/filestore",
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


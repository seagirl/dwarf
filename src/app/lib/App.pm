package App;
use Dwarf::Pragma;
use parent 'Dwarf';
use Dwarf::Util 'load_class';
use App::Constant;
use Class::Method::Modifiers;

sub setup {
	my $self = shift;

	umask 002;

	$self->load_plugins(
		'MultiConfig' => {
			production  => 'production',
			development => [
				'development' => '<APP_NAME>',
			],
		},
 	);

	$self->load_plugins(
		'Teng'    => {},
		'Now'     => { time_zone => 'Asia/Tokyo' },
		'Runtime' => {
			cli    => 0,
			ignore => 'production'
		},
	);

	$self->load_plugins(
		'Text::Xslate' => {
			path      => [ $self->base_dir . '/tmpl' ],
			cache_dir => $self->base_dir . '/.xslate_cache',
		},
   );
}

# デフォルトのルーティングに追加したい場合は記述する
after add_routes => sub {
	my $self = shift;
	# eg) name notation を使いたい
	# $self->router->connect("/images/detail/:id", { controller => "Web::Images::Detail" });
};

sub base_url {
	my ($self) = @_;
	my $key = $self->conf('ssl') ? 'ssl_base' : 'base';
	my $url = $self->conf('url')->{$key};
	return $url ? $url : $self->conf('url')->{base};
}

1;


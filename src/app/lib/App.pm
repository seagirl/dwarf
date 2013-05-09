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
}

# デフォルトのルーティングに追加したい場合はルーティングを記述する
before add_routes => sub {
	my $self = shift;
	# eg) name notation を使いたい場合の書き方 (パラメータ user_id に値が渡る)
	# $self->router->connect("/images/detail/:user_id", { controller => "Web::Images::Detail" });
};

sub base_url {
	my ($self) = @_;
	my $key = $self->conf('ssl') ? 'ssl_base' : 'base';
	my $url = $self->conf('url')->{$key};
	return $url ? $url : $self->conf('url')->{base};
}

1;


package App;
use Dwarf::Pragma;
use parent 'Dwarf';
use Class::Method::Modifiers;
use App::Constant;

sub setup {
	my $self = shift;

	umask 002;

	$self->load_plugins(
		'MultiConfig' => {
			production  => 'Production',
			development => [
				'Development' => '<APP_NAME>.s2factory.co.jp',
				'Seagirl'     => 'seagirl.local',
			],
		},
 	);

	$self->load_plugins(
		'Teng'    => {},
		'URL'     => {},
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

1;


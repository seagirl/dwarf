package App::Controller::WebBase;
use Dwarf::Pragma;
use Dwarf::DSL;
use parent 'Dwarf::Module::HTMLBase';
use App::Constant;

sub will_dispatch {
	my ($self, $c) = @_;

#	load_plugins(
#		'CGI::Session' => {
#			dbh             => db('master')->dbh,
#			table           => SES_TABLE,
#			session_key     => SES_KEY,
#			cookie_path     => '/',
#			cookie_secure   => TRUE,
#			param_name      => 'session_id',
#			on_init         => sub {
#			},
#		},
#	);
}

# テンプレートに渡す共通の値を定義することなどに使う
# 例）ヘッダなど
# sub will_render {
#	my ($self, $c, $data) = @_;
# }

1;


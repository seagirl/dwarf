package App::Controller::WebBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::HTMLBase';
use Dwarf::DSL;
use App::Constant;

sub will_dispatch {
	load_plugins(
		'Text::Xslate' => {
			path      => [ c->base_dir . '/tmpl' ],
			cache_dir => c->base_dir . '/.xslate_cache',
		},
#		'CGI::Session' => {
#			dbh             => db('master')->dbh,
#			table         => conf('/session/store/table'),
#			session_key   => conf('/session/state/name'),
#			cookie_path     => '/',
#			cookie_secure   => TRUE,
#			param_name      => 'session_id',
#			on_init         => sub {
#			},
#		},
	);
}

# テンプレートに渡す共通の値を定義することなどに使う
# 例）ヘッダなど
# sub will_render {
#	my ($self, $c, $data) = @_;
# }

1;


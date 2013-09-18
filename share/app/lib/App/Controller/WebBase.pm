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
		'HTTP::Session' => {
			session_key         => conf('/session/state/name'),
			session_table       => conf('/session/store/table'),
			session_expires     => 60 * 60 * 24,
			session_clean_thres => 1,
			param_name          => 'session_id',
			cookie_path         => '/',
			cookie_domain       => undef,
			cookie_expires      => undef,
			cookie_secure       => false,
		},
	);
}

# テンプレートに渡す共通の値を定義することなどに使う
# 例）ヘッダなど
# sub will_render {
#	my ($self, $c, $data) = @_;
# }

1;


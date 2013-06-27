use App::Test;
App::Test->new(sub {
	my ($c, $cb) = @_;

	subtest "config" => sub {
		ok $c->can('config'), 'got context';
		like $c->base_dir, qr|^/.*/app$|, 'have base_dir';
	};

	subtest "request" => sub {
		get_ok($cb, "/");

		SKIP: {
			skip("Because Cli modules and Api::ShowSession is not working on production", 1)
				if $c->is_production;
			get_ok($cb, "/api/show_session");
			get_ok($cb, "/cli/ping");
		}
	};
})->run;


use App::Test;
App::Test->new(sub {
	my ($c, $cb) = @_;

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


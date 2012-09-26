use App::Test;
App::Test->new(\&t1, \&t2)->run;

sub t1 {
	my ($c, $cb) = @_;
	warn "[t1]";
	ok $c->can('config'), 'got context';
	like $c->base_dir, qr|^/.*/app$|, 'have base_dir';
}

sub t2 {
	my ($c, $cb) = @_;
	warn "[t2]";
	get_ok($cb, "/web/index");
	SKIP: {
		skip("Because Cli modules and Api::ShowSession is not working on production", 1)
			if $c->is_production;
		get_ok($cb, "/api/show_session");
		get_ok($cb, "/cli/ping");
	}
}


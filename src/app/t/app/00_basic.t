use App::Test;
App::Test->new(\&t1)->run;

sub t1 {
	my ($c, $cb) = @_;
	ok $c->can('config'), 'got context';
	like $c->base_dir, qr|^/.*/app$|, 'have base_dir';
	get_ok($cb, "/web/index");
	get_ok($cb, "/api/show_session");
	get_ok($cb, "/cli/ping") unless $c->is_production;
}


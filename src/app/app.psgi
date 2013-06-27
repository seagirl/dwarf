use Plack::Builder;
use App;

builder {
	enable "Plack::Middleware::ContentLength";
	enable "Plack::Middleware::Static", path => qr{^/(dwarf)/}, root => '../htdocs/';
	sub {
		App->new(env => shift)->to_psgi;
	};
};




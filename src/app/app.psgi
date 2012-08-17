use Plack::Builder;
use App;

builder {
	enable "Plack::Middleware::ContentLength";
	sub {
		App->new(env => shift)->to_psgi;
	};
};




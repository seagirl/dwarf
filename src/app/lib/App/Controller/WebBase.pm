package App::Controller::WebBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module::WebBase';
use Text::Xslate qw/html_escape html_builder/;
use Dwarf::Util qw/hash_merge/;
use S2Factory::Validator;
use App::Constant;

use Dwarf::Accessor qw/auth/;

sub init {
	my ($self, $c) = @_;

	S2Factory::Validator->load_constraints(qw/Japanese URL/);
	S2Factory::Validator->load_constraints('+S2Factory::Validator::Range');
	S2Factory::Validator->load_constraints('+UUAW::Validator::Length');

	$c->add_trigger('BEFORE_RENDER' => $self->include_header);
	$c->load_plugins(
		'Error' => {
			ERROR                => sub { shift->throw(99, @_)->flush },
			PARAM_ERROR          => sub { shift->throw(1, @_) },
			NO_DATA_EXISTS_IN_DB => sub { shift->throw(2,  sprintf("No data exists in DB: %s", $_[0] || ""))->flush },
		},
		'CGI::Session' => {
			dbh             => $self->db('master')->dbh,
			table           => SES_TABLE,
			session_key     => SES_KEY,
			cookie_path     => '/',
#			cookie_secure   => TRUE,
			param_name      => 'session_id',
			on_init         => sub {
			},
		},
		'Text::Xslate' => {
			path      => [ $c->base_dir . '/tmpl' ],
			cache_dir => $c->base_dir . '/.xslate_cache',
			function  => {
			},
		},
	);

	$self->type('text/html; charset=UTF-8');
	$self->before($c);
	$self->error->flush;
}

sub include_header {
	my ($self) = @_;
	return sub {
		my ($c, $data) = @_;
	};
}

sub before {}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;
	my $validator = S2Factory::Validator->new($self->req)->check(@rules);
	if ($validator->has_error) {
		while (my ($param, $detail) = each %{ $validator->errors }) {
			$self->throw_error($self->c, $param, $detail);
		}
	}
}

# Form::Validator のエラー発生時にどう扱うかをカスタマイズ
sub throw_error {
	my ($self, $c, $param, $detail) = @_;
	$c->error->PARAM_ERROR($param, $detail);
}

# die した後のハンドリングを記述する
sub on_error {
	my ($self, $c, $error) = @_;

	$self->{error_vars} ||= $self->req->parameters->as_hashref;
	$self->{error_vars}->{error} = {};

	for my $message (@{ $error->messages }) {
		my $code = $message->body->[0];
		my $param  = $message->body->[1];
		my $detail = $message->body->[2];
		my $vars   = $message->body->[3];
		for my $k (keys %{ $vars }) {
			$self->{error_vars}->{$k} = $vars->{ $k };
		}
		$self->{error_vars}->{error}->{$param} = hash_merge(
			$self->{error_vars}->{error}->{$param},
			$detail
		);
	}

	return $c->render($self->error_template, $self->error_vars);
}

1;


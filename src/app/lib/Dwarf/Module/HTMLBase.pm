package Dwarf::Module::HTMLBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::Util qw/hash_merge/;
use Dwarf::Util::Xslate qw/reproduce_line_feed/;
use S2Factory::Validator;

use Dwarf::Accessor qw/
	error_template error_vars
	server_error_template server_error_vars
/;

sub init {
	my ($self, $c) = @_;

	S2Factory::Validator->load_constraints(qw/Japanese URL/);
	S2Factory::Validator->load_constraints('+S2Factory::Validator::Range');
	S2Factory::Validator->load_constraints('+S2Factory::Validator::MBLength');

	$c->load_plugins(
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, @_) },
			INVALID_PARAM   => sub { shift->throw(1002, @_) },
			ERROR           => sub { shift->throw( 400, @_)->flush },
		},
		'Text::Xslate' => {
			path      => [ $c->base_dir . '/tmpl' ],
			cache_dir => $c->base_dir . '/.xslate_cache',
			function  => {
				lf => reproduce_line_feed,
			},
		},
	);

	$c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
	$c->add_trigger(AFTER_RENDER => $self->can('did_render'));
	$c->add_trigger(ERROR => $self->can('receive_error'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));

	$self->type('text/html; charset=UTF-8');
	$self->will_dispatch($c);
	$self->error->flush;
}

sub will_dispatch {}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;
	my $validator = S2Factory::Validator->new($self->req)->check(@rules);
	if ($validator->has_error) {
		while (my ($param, $detail) = each %{ $validator->errors }) {
			$self->c->error->LACK_OF_PARAM($param, $detail) if $detail->{NOT_NULL};
			$self->c->error->INVALID_PARAM($param, $detail);
		}
	}
}

# レンダリング前の共通処理
sub will_render {
	my ($self, $c, $data) = @_;
}

# レンダリング後の共通処理
sub did_render {
	my ($self, $c, $data) = @_;
}

# 400 系のエラー
sub receive_error {
	my ($self, $c, $error) = @_;

	$self->{error_template} ||= '400.html';
	$self->{error_vars}     ||= $self->req->parameters->as_hashref;

	for my $message (@{ $error->messages }) {
		my $code   = $message->data->[0];
		my $param  = $message->data->[1];
		my $detail = $message->data->[2];

		$self->{error_vars}->{error}->{$param} = hash_merge(
			$self->{error_vars}->{error}->{$param},
			$detail
		);
	}

	return $c->render($self->error_template, $self->error_vars);
}

# 500 系のエラー
sub receive_server_error {
	my ($self, $c, $error) = @_;
	$self->{server_error_template}    ||= '500.html';
	$self->{server_error_vars} ||= { error => $error };
	return $c->render($self->server_error_template, $self->server_error_vars);
}

1;


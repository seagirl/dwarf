package Dwarf::Module::APIBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use S2Factory::Validator;

sub init {
	my ($self, $c) = @_;

	S2Factory::Validator->load_constraints(qw/Japanese URL Email/);
	S2Factory::Validator->load_constraints('+S2Factory::Validator::Range');
	S2Factory::Validator->load_constraints('+S2Factory::Validator::MBLength');

	$c->load_plugins(
		'JSON'  => { pretty => 1 },
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
		},
	);

	# バリデーション時に全部まとめてエラーハンドリングしたい場合はコメントアウトする
	$c->error->autoflush(1);

	$c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
	$c->add_trigger(AFTER_RENDER => $self->can('did_render'));
	$c->add_trigger(ERROR => $self->can('receive_error'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));

	$self->type('application/json; charset=UTF-8');
	$self->will_dispatch($c);
	$self->error->flush;
}

sub will_dispatch {}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;

	my $validator = S2Factory::Validator->new($self->c->req)->check(@rules);
	if ($validator->has_error) {
		while (my ($param, $detail) = each %{ $validator->errors }) {
			$self->c->error->LACK_OF_PARAM($param) if $detail->{NOT_NULL};
			$self->c->error->INVALID_PARAM($param);
		}
	}
}

# レンダリング前の共通処理
sub will_render {
	my ($self, $c, $data) = @_;
	$self->response_http_status($data);
}

# レンダリング後の共通処理
sub did_render {
	my ($self, $c, $data) = @_;
}

# 400 系のエラー
sub receive_error {
	my ($self, $c, $error) = @_;
	my (@codes, @messages);

	for my $m (@{ $error->messages }) {
		warn sprintf "API Error: code = %s, message = %s", $m->data->[0], $m->data->[1];
		push @codes, $m->data->[0];
		push @messages, $m->data->[1];
	}

	my $data = {
		error_code    => @codes == 1 ? $codes[0] : \@codes,
		error_message => @messages == 1 ? $messages[0] : \@messages,
	};

	return $data;
}

# 500 系のエラー
sub receive_server_error {
	my ($self, $c, $error) = @_;

	$error ||= 'Internal Server Error';

	my $data = {
		error_code    => 500,
		error_message => $error,
	};

	return $data;
}

# HTTP ステータスの調整
sub response_http_status {
	my ($self, $data) = @_;
	$data ||= {};

	my $status = 200;
	if ($data->{error_code}) {
		$status = $data->{error_code} == 500 ? 500 : 400;
	}

	if (defined $self->param('response_http_status')) {
		$self->status(scalar $self->param('response_http_status'));
		$data->{http_status} ||= $status;
		$status = 200;
	}

	$self->res->status($status);
}

1;

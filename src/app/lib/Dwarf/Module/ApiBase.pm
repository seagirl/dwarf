package Dwarf::Module::ApiBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use S2Factory::Validator;

sub init = {
	my ($self, $c) = @_;

	$c->load_plugins(
		'Error' => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
		},
	);

	$c->error->autoflush(1);

	$c->add_trigger(BEFORE_RENDER => \&will_render);
	$c->add_trigger(AFTER_RENDER => \&did_render);
	$c->add_trigger(ERROR => \&recive_error);
	$c->add_trigger(SERVER_ERROR => \&recive_server_error);

	$self->before($c);
}

sub before {}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;

	my $validator = S2Factory::Validator->new($self->c->req)->check(@rules);
	if ($validator->has_error) {
		for my $key (sort keys %{ $validator->errors }) {
			my $value = $validator->errors->{$key};
			$self->c->error->LACK_OF_PARAM($key) if $value->{NOT_NULL};
			$self->c->error->INVALID_PARAM($key);
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
sub recive_error {
	my ($self, $c, $error) = @_;
	my (@codes, @messages);

	for my $m (@{ $error->messages }) {
		warn sprintf "API Error: code = %s, message = %s", $m->body->[0], $m->body->[1];
		push @codes, $m->body->[0];
		push @messages, $m->body->[1];
	}

	my $data = {
		error_code    => @codes == 1 ? $codes[0] : \@codes,
		error_message => @messages == 1 ? $messages[0] : \@messages,
	};

	return $data;
}

# 500 系のエラー
sub recive_server_error {
	my ($self, $c, $error) = @_;

	$error ||= 'Internal Server Error';

	my $data = {
		error_code    => 500,
		error_message => $error,
	};

	return $data;
}

# HTTP ステータスの調整
sub http_response_status {
	my ($self, $data) = @_;
	$data ||= {}:

	my $status = 200;
	if ($data->{error_code}) {
		$status = $data->{error_code} == 500 ? 500 : 400;
	}

	if (defined $self->param('response_http_status')) {
		$self->status(scalar $c->param('response_http_status'));
		$data->{http_status} ||= $staus;
		$status = 200;
	}

	$self->res->status($status);
}

1;

package Dwarf::Module::APIBase;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::Validator;
use HTTP::Date;

sub init {
	my ($self, $c) = @_;

	Dwarf::Validator->load_constraints(qw/Japanese URL Email Date Time/);
	Dwarf::Validator->load_constraints('+Dwarf::Validator::Number');
	Dwarf::Validator->load_constraints('+Dwarf::Validator::Array');
	Dwarf::Validator->load_constraints('+Dwarf::Validator::JSON');
	Dwarf::Validator->load_constraints('+Dwarf::Validator::File');
	Dwarf::Validator->load_constraints('+Dwarf::Validator::Filter');

	# バリデーション時に全部まとめてエラーハンドリングしたい場合はコメントアウトする
	$c->error->autoflush(1);

	$c->add_trigger(BEFORE_RENDER => $self->can('will_render'));
	$c->add_trigger(AFTER_RENDER => $self->can('did_render'));
	$c->add_trigger(ERROR => $self->can('receive_error'));
	$c->add_trigger(SERVER_ERROR => $self->can('receive_server_error'));
	
	$self->header('Pragma' => 'no-cache');
	$self->header('Cache-Control' => 'no-cache');
	$self->header('Expires' => HTTP::Date::time2str(time - 24 * 60 * 60));
	$self->header('X-Content-Type-Options' => 'nosniff'); # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
	$self->header('X-Frame-Options' => 'DENY'); # http://blog.mozilla.com/security/2010/09/08/x-frame-options/

	
	$self->init_plugins($c);

	$self->type('application/json; charset=UTF-8');

	if (defined $c->ext and $c->ext eq 'xml' and $c->can('encode_xml')) {
		$self->type('application/xml; charset=UTF-8');
	}

	$self->call_before_trigger($c);
	$self->will_dispatch($c);
	$self->error->flush;
}

sub init_plugins  {
	my ($self, $c) = @_;

	$c->load_plugins(
		'Error'       => {
			LACK_OF_PARAM   => sub { shift->throw(1001, sprintf("missing mandatory parameters: %s", $_[0] || "")) },
			INVALID_PARAM   => sub { shift->throw(1002, sprintf("illegal parameter: %s", $_[0] || "")) },
			NEED_TO_LOGIN   => sub { shift->throw(1003, sprintf("You must login.")) },
			SNS_LIMIT_ERROR => sub { shift->throw(2001, sprintf("SNS Limit Error: reset at %s", $_[0] || "")) },
			SNS_ERROR       => sub { shift->throw(2002, sprintf("SNS Error: %s", $_[0] || "SNS Error.")) },
			ERROR           => sub { shift->throw(400,  sprintf("%s", $_[0] || "Unknown Error.")) },
		},
		'JSON'        => { pretty => 1 },
		'XML::Simple' => {
			NoAttr        => 1,
			KeyAttr       => [],
			SuppressEmpty => '' 
		},
	);
}

sub call_before_trigger {
	my ($self, $c) = @_;
	$c->call_trigger(BEFORE_DISPATCH => $c, $c->request);
}

sub will_dispatch {}

sub validate {
	my ($self, @rules) = @_;
	return unless @rules;

	my $validator = Dwarf::Validator->new($self->c->req)->check(@rules);
	if ($validator->has_error) {
		while (my ($param, $detail) = each %{ $validator->errors }) {
			$self->c->error->LACK_OF_PARAM($param) if $detail->{NOT_NULL};
			$self->c->error->LACK_OF_PARAM($param) if $detail->{FILE_NOT_NULL};
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
		print STDERR sprintf "[API Error] code = %s, message = %s\n", $m->data->[0], $m->data->[1];
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

	print STDERR sprintf "[Server Error] %s\n", $error;

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

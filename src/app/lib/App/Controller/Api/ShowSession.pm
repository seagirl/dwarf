package App::Controller::Api::ShowSession;
use Dwarf::Pragma;
use parent 'App::Controller::ApiBase';
use Encode ();
use Scalar::Util qw(blessed refaddr);

sub before {
	my ($self, $c) = @_;
}

sub get {
	my ($self, $c) = @_;

	# 本番では動かないように
	if ($c->is_production) {
		return $c->not_found;
	}

	my $session = $self->session->dataref;
	my $cookie  = $self->c->req->cookies;

	return {
		id       => $self->session->id,
		session  => $self->decode_utf8($session),
		cookie   => $self->decode_utf8($cookie)
	};
}

sub decode_utf8 {
    my ($class, $stuff, $check) = @_;
    _apply(sub { Encode::decode_utf8($_[0], $check) }, {}, $stuff);
}

sub _apply {
    my $code = shift;
    my $seen = shift;

    my @retval;
    for my $arg (@_) {
        if(my $ref = ref $arg){
            my $refaddr = refaddr($arg);
            my $proto;

            if(defined($proto = $seen->{$refaddr})){
                 # noop
            }
            elsif($ref eq 'ARRAY'){
                $proto = $seen->{$refaddr} = [];
                @{$proto} = _apply($code, $seen, @{$arg});
            }
            elsif($ref eq 'HASH'){
                $proto = $seen->{$refaddr} = {};
                %{$proto} = _apply($code, $seen, %{$arg});
            }
            elsif($ref eq 'REF' or $ref eq 'SCALAR'){
                $proto = $seen->{$refaddr} = \do{ my $scalar };
                ${$proto} = _apply($code, $seen, ${$arg});
            }
            else{ # CODE, GLOB, IO, LVALUE etc.
                $proto = $seen->{$refaddr} = $arg;
            }

            push @retval, $proto;
        }
        else{
            push @retval, defined($arg) ? $code->($arg) : $arg;
        }
    }

    return wantarray ? @retval : $retval[0];
}

1;

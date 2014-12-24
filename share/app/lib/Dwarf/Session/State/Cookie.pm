package Dwarf::Session::State::Cookie;
use Dwarf::Pragma;
use parent 'HTTP::Session::State::Cookie';
use Dwarf::Accessor qw/param_name/;

sub get_session_id {
    my ($self, $req) = @_;
    Carp::croak "missing req" unless $req;
    my $id = $self->SUPER::get_session_id($req);
    if (ref $self->param_name eq 'ARRAY') {
        for my $param_name (@{ $self->param_name }) {
            $id ||= $req->param($param_name);
        }
    } else {
        $id ||= $req->param($self->param_name);
    }
    return $id;
}

1;
package Dwarf::Backend;

use strict;
use warnings;

use Carp ();
use Scalar::Util qw(refaddr);

my %keys;
my %values;

if (defined &UNIVERSAL::ref::import) {
    UNIVERSAL::ref->import;
}

sub ref { 'HASH' }

sub create {
    my $class = shift;
    my $self = bless {}, $class;
    my $this = refaddr $self;
    $keys{$this} = [];
    $values{$this} = [];
    $self;
}

sub new {
    my $class = shift;
    my $self = $class->create;
    unshift @_, $self;
    goto &{ $self->can('merge_flat') };
}

sub from_mixed {
    my $class = shift;
    my $self = $class->create;
    unshift @_, $self;
    goto &{ $self->can('merge_mixed') };
}

sub DESTROY {
    my $this = refaddr shift;
    delete $keys{$this};
    delete $values{$this};
}

sub get {
    my($self, $key) = @_;
    $self->{$key};
}

sub get_all {
    my($self, $key) = @_;
    my $this = refaddr $self;
    my $k = $keys{$this};
    (@{$values{$this}}[grep { $key eq $k->[$_] } 0 .. $#$k]);
}

sub get_one {
    my ($self, $key) = @_;
    my @v = $self->get_all($key);
    return $v[0] if @v == 1;
    Carp::croak "Key not found: $key" if not @v;
    Carp::croak "Multiple values match: $key";
}

sub add {
    my $self = shift;
    my $key = shift;
    $self->merge_mixed( $key => \@_ );
    $self;
}

sub merge_flat {
    my $self = shift;
    my $this = refaddr $self;
    my $k = $keys{$this};
    my $v = $values{$this};
    push @{ $_ & 1 ? $v : $k }, $_[$_] for 0 .. $#_;
    @{$self}{@$k} = @$v;
    $self;
}

sub merge_mixed {
    my $self = shift;
    my $this = refaddr $self;
    my $k = $keys{$this};
    my $v = $values{$this};

    my $hash;
    $hash = shift if @_ == 1;

    while ( my ($key, $value) = @_ ? splice @_, 0, 2 : each %$hash ) {
        my @value = CORE::ref($value) eq 'ARRAY' ? @$value : $value;
        next if not @value;
        $self->{$key} = $value[-1];
        push @$k, ($key) x @value;
        push @$v, @value;
    }

    $self;
}

sub remove {
    my ($self, $key) = @_;
    delete $self->{$key};

    my $this = refaddr $self;
    my $k = $keys{$this};
    my $v = $values{$this};
    my @keep = grep { $key ne $k->[$_] } 0 .. $#$k;
    @$k = @$k[@keep];
    @$v = @$v[@keep];
    $self;
}

sub clear {
    my $self = shift;
    %$self = ();
    my $this = refaddr $self;
    $keys{$this} = [];
    $values{$this} = [];
    $self;
}

sub clone {
    my $self = shift;
    CORE::ref($self)->new($self->flatten);
}

sub keys {
    my $self = shift;
    return @{$keys{refaddr $self}};
}

sub values {
    my $self = shift;
    return @{$values{refaddr $self}};
}

sub flatten {
    my $self = shift;
    my $this = refaddr $self;
    my $k = $keys{$this};
    my $v = $values{$this};
    map { $k->[$_], $v->[$_] } 0 .. $#$k;
}

sub each {
    my ($self, $code) = @_;
    my $this = refaddr $self;
    my $k = $keys{$this};
    my $v = $values{$this};
    for (0 .. $#$k) {
        $code->($k->[$_], $v->[$_]);
    }
    return $self;
}

sub as_hashref {
    my $self = shift;
    my %hash = %$self;
    \%hash;
}

sub as_hashref_mixed {
    my $self = shift;
    my $this = refaddr $self;
    my $k = $keys{$this};
    my $v = $values{$this};

    my %hash;
    push @{$hash{$k->[$_]}}, $v->[$_] for 0 .. $#$k;
    for (CORE::values %hash) {
        $_ = $_->[0] if 1 == @$_;
    }

    \%hash;
}

sub mixed { $_[0]->as_hashref_mixed }

sub as_hashref_multi {
    my $self = shift;
    my $this = refaddr $self;
    my $k = $keys{$this};
    my $v = $values{$this};

    my %hash;
    push @{$hash{$k->[$_]}}, $v->[$_] for 0 .. $#$k;

    \%hash;
}

sub multi { $_[0]->as_hashref_multi }

1;
